import {ImageAnnotatorClient} from "@google-cloud/vision";
import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

import {extractOcrFields, VerificationRequestData} from "./ocr/extractFields";

admin.initializeApp();
setGlobalOptions({maxInstances: 10, region: "asia-southeast1"});

const visionClient = new ImageAnnotatorClient();
const db = admin.firestore();
const storage = admin.storage();

type VerificationRequest = VerificationRequestData & {
  documentUrl?: string;
  storagePath?: string;
};

export const processVerificationRequestOcr = onDocumentCreated(
  "verificationRequests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const requestId = event.params.requestId;
    const data = snapshot.data() as VerificationRequest;
    const requestRef = db.collection("verificationRequests").doc(requestId);
    const storagePath =
      data.storagePath?.trim() ||
      storagePathFromDownloadUrl(data.documentUrl ?? "");

    if (!storagePath) {
      await requestRef.update({
        ocrStatus: "failed",
        ocrError:
          "Missing storagePath and could not derive it from documentUrl.",
        ocrProcessedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    await requestRef.update({
      ocrStatus: "processing",
      ocrError: FieldValue.delete(),
      storagePath,
    });

    try {
      const bucket = storage.bucket();
      const gcsUri = `gs://${bucket.name}/${storagePath}`;
      const mimeType = mimeTypeForPath(storagePath);
      const rawText = await extractTextFromGcsFile({
        bucketName: bucket.name,
        gcsUri,
        mimeType,
        requestId,
      });

      const trimmedText = rawText.trim();
      if (!trimmedText) {
        throw new Error("No readable text was detected in this document.");
      }

      const fields = extractOcrFields(trimmedText, data);
      await requestRef.update({
        ocrStatus: "completed",
        ocrText: trimmedText,
        ocrFields: fields,
        ocrStructuredData: FieldValue.delete(),
        ocrReviewedAt: FieldValue.delete(),
        ocrReviewedBy: FieldValue.delete(),
        ocrError: FieldValue.delete(),
        ocrProcessedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error("Verification OCR failed", {requestId, error});
      await requestRef.update({
        ocrStatus: "failed",
        ocrError: errorMessage(error),
        ocrProcessedAt: FieldValue.serverTimestamp(),
      });
    }
  },
);

async function extractTextFromGcsFile(args: {
  bucketName: string;
  gcsUri: string;
  mimeType: string;
  requestId: string;
}): Promise<string> {
  if (args.mimeType === "application/pdf") {
    return extractPdfText(args.bucketName, args.gcsUri, args.requestId);
  }
  return extractImageText(args.gcsUri);
}

async function extractImageText(gcsUri: string): Promise<string> {
  const [result] = await visionClient.documentTextDetection({
    image: {source: {imageUri: gcsUri}},
  });
  return (
    result.fullTextAnnotation?.text ??
    result.textAnnotations?.[0]?.description ??
    ""
  );
}

async function extractPdfText(
  bucketName: string,
  gcsUri: string,
  requestId: string,
): Promise<string> {
  const outputPrefix = `_ocr_outputs/${requestId}/`;
  const destinationUri = `gs://${bucketName}/${outputPrefix}`;

  const [operation] = await visionClient.asyncBatchAnnotateFiles({
    requests: [
      {
        inputConfig: {
          gcsSource: {uri: gcsUri},
          mimeType: "application/pdf",
        },
        features: [{type: "DOCUMENT_TEXT_DETECTION"}],
        outputConfig: {
          gcsDestination: {uri: destinationUri},
          batchSize: 5,
        },
      },
    ],
  });
  await operation.promise();

  const bucket = storage.bucket(bucketName);
  const [files] = await bucket.getFiles({prefix: outputPrefix});
  const jsonFiles = files.filter((file) => file.name.endsWith(".json"));
  if (jsonFiles.length === 0) {
    throw new Error("Vision did not produce OCR output for this PDF.");
  }

  const parts: string[] = [];
  for (const file of jsonFiles) {
    const [content] = await file.download();
    const parsed = JSON.parse(content.toString("utf8")) as VisionPdfOutput;
    for (const response of parsed.responses ?? []) {
      const pageText =
        response.fullTextAnnotation?.text ??
        response.textAnnotations?.[0]?.description ??
        "";
      if (pageText.trim()) parts.push(pageText.trim());
    }
  }

  await Promise.all(files.map((file) => file.delete().catch(() => undefined)));
  return parts.join("\n\n");
}

function mimeTypeForPath(storagePath: string): string {
  const lower = storagePath.toLowerCase().split("?")[0];
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
  return "image/jpeg";
}

function storagePathFromDownloadUrl(documentUrl: string): string {
  if (!documentUrl.trim()) return "";
  try {
    const url = new URL(documentUrl);
    const marker = "/o/";
    const markerIndex = url.pathname.indexOf(marker);
    if (markerIndex === -1) return "";

    const encodedPath = url.pathname.substring(markerIndex + marker.length);
    if (!encodedPath) return "";

    return decodeURIComponent(encodedPath);
  } catch {
    return "";
  }
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

interface VisionPdfOutput {
  responses?: Array<{
    fullTextAnnotation?: {text?: string};
    textAnnotations?: Array<{description?: string}>;
  }>;
}

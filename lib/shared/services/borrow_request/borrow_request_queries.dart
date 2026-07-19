// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : borrow_request_queries.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../borrow_request_service.dart';

mixin _BorrowRequestQueriesMixin on _BorrowRequestServiceBase {
  Stream<List<BorrowRequest>> watchMyBorrowRequests(String borrowerId) {
    return _requests.where('borrowerId', isEqualTo: borrowerId).snapshots().map(
      (snapshot) {
        final list = snapshot.docs
            .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  Stream<List<BorrowRequest>> watchIncomingRequests(String ownerId) {
    return _requests.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final list = snapshot.docs
          .map((doc) => BorrowRequest.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<BorrowRequest?> fetchBorrowRequest(String requestId) async {
    final snap = await _requests.doc(requestId).get();
    final data = snap.data();
    if (data == null) return null;
    return BorrowRequest.fromMap(snap.id, data);
  }
}

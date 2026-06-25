part of '../ocr_parser_service.dart';

const _tenancyLabelsTenantName = [
  'Tenant',
  'Tenant Name',
  'Name of Tenant',
  'Resident Name',
  'Occupant Name',
  'Lessee',
];

const _tenancyLabelsUnitNumber = [
  'Unit',
  'Unit Number',
  'Premises Unit',
  'Apartment No',
  'Apartment Number',
  'House No',
  'House Number',
  'Lot No',
];

const _tenancyLabelsPropertyAddress = [
  'Address',
  'Property Address',
  'Premises Address',
  'Residence Address',
  'Building Address',
  'Premises Unit',
  'Property Name',
  'Residence Name',
  'Condominium',
  'Apartment Name',
];

const _tenancyLabelsLandlordName = [
  'Landlord',
  'Landlord Name',
  'Landlord / Owner',
  'Owner',
  'Owner Name',
  'Lessor',
];

const _tenancyLabelsAgreementDate = [
  'Date',
  'Agreement Date',
  'Start Date',
  'Tenancy Date',
  'Commencement Date',
];

const _utilityLabelsTenantName = [
  'Bill Holder Name',
  'Bill Holder',
  'Tenant',
  'Tenant Name',
  'Customer Name',
  'Account Name',
  'Name',
  'Registered Name',
];

const _utilityLabelsAccountNumber = [
  'Account Number',
  'Account No',
  'Account',
  'Customer Number',
  'Customer No',
  'Contract Account',
];

const _utilityLabelsPropertyAddress = [
  'Service Address',
  'Property Address',
  'Premises Address',
  'Billing Address',
  'Supply Address',
  'Address',
];

const _utilityLabelsBillDate = [
  'Bill Date',
  'Billing Date',
  'Invoice Date',
  'Statement Date',
  'Date',
];

const _utilityLabelsDueDate = [
  'Due Date',
  'Payment Due Date',
  'Pay By Date',
  'Pay Before',
];

const _utilityLabelsProvider = [
  'Utility Provider',
  'Utility Issuer or Provider',
  'Provider',
  'Issuer',
  'Supplier',
  'Company',
];

const _utilityLabelsType = [
  'Utility Type',
  'Bill Type',
  'Service Type',
  'Type',
];

const _amountLabels = [
  'Amount Due',
  'Total Amount',
  'Total Payable',
  'Balance Due',
  'Current Charges',
  'Amount',
];

const _accessLabelsPropertyAddress = [
  'Property Address',
  'Residence Address',
  'Building',
  'Condominium',
  'Apartment',
  'Apartment Name',
  'Address',
];

const _accessLabelsUnitNumber = [
  'Unit',
  'Unit Number',
  'Apartment No',
  'Apartment Number',
  'House No',
  'House Number',
  'Lot No',
];

const _accessLabelsCardNumber = [
  'Card Number',
  'Card No',
  'Card ID',
  'Access Card Number',
  'Access Card No',
  'RFID Number',
  'RFID No',
  'Resident Card Number',
];

const _allLabels = [
  ..._tenancyLabelsTenantName,
  ..._tenancyLabelsUnitNumber,
  ..._tenancyLabelsPropertyAddress,
  ..._tenancyLabelsLandlordName,
  ..._tenancyLabelsAgreementDate,
  ..._utilityLabelsTenantName,
  ..._utilityLabelsAccountNumber,
  ..._utilityLabelsPropertyAddress,
  ..._utilityLabelsBillDate,
  ..._utilityLabelsDueDate,
  ..._utilityLabelsProvider,
  ..._utilityLabelsType,
  ..._amountLabels,
  ..._accessLabelsPropertyAddress,
  ..._accessLabelsUnitNumber,
  ..._accessLabelsCardNumber,
  'Landlord / Owner',
  'Landlord ID',
  'Landlord Address',
  'Landlord Contact',
  'Tenant ID',
  'Tenant Current Address',
  'Tenant Contact',
  'Car Park / Access Card',
  'Tenancy Term',
  'Monthly Rent',
  'Payment Due Date',
  'Security Deposit',
  'Utility Deposit',
  'Advance Rental',
  'Permitted Use',
  'Number of Occupants',
  'Bill Type',
  'Type',
];

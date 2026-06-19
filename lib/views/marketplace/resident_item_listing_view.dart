import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jirani/core/constants/app_constants.dart';
import 'package:jirani/core/utils/item_listing_form.dart';
import 'package:jirani/core/utils/responsive.dart';
import 'package:jirani/providers/item_provider.dart';
import 'package:jirani/shared/models/app_user.dart';
import 'package:jirani/shared/models/item_model.dart';
import 'package:jirani/shared/widgets/jirani_background.dart';
import 'package:jirani/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

const Color _kBrandTeal = Color(0xFF006D77);
const Color _kDanger = Color(0xFFB00020);
const Color _kInk = Color(0xFF1F2937);
const Color _kMutedText = Color(0xFF6B7280);
const double _kMaxContentWidth = 440;
const int _kMaxPhotos = 5;

class ResidentMyItemsView extends StatefulWidget {
  const ResidentMyItemsView({super.key});

  @override
  State<ResidentMyItemsView> createState() => _ResidentMyItemsViewState();
}

class _ResidentMyItemsViewState extends State<ResidentMyItemsView> {
  String? _watchingUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || _watchingUid == user.uid) return;
    _watchingUid = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ItemProvider>().watchMyItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final sideInset = JiraniResponsive.scaled(context, 20);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _InsetContent(
                  sideInset: sideInset,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'My Items',
                              style: TextStyle(
                                color: _kInk,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _CircleIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Add item',
                            onTap: user == null
                                ? () => _showSnack(
                                    context,
                                    'Sign in before listing an item.',
                                  )
                                : () => _openListingForm(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ProfileListingSummary(user: user),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Consumer<ItemProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.myItems.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _InsetContent(
                        sideInset: sideInset,
                        child: const _StateCard(
                          icon: Icons.hourglass_top_rounded,
                          title: 'Loading your items',
                          message:
                              'Checking your active and archived listings.',
                        ),
                      ),
                    );
                  }

                  final error = provider.errorMessage;
                  if (error != null && error.isNotEmpty) {
                    return SliverToBoxAdapter(
                      child: _InsetContent(
                        sideInset: sideInset,
                        child: _StateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Items unavailable',
                          message: error.replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }

                  final items = provider.myItems;
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _InsetContent(
                        sideInset: sideInset,
                        child: _EmptyMyItemsCard(
                          onAdd: user == null
                              ? null
                              : () => _openListingForm(context),
                        ),
                      ),
                    );
                  }

                  return SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _InsetContent(
                        sideInset: sideInset,
                        child: _MyItemCard(
                          item: item,
                          onEdit: () => _openListingForm(context, item: item),
                          onArchive: item.isArchived
                              ? null
                              : () => _confirmArchive(context, item),
                        ),
                      );
                    },
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  void _openListingForm(BuildContext context, {ItemModel? item}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResidentItemListingFormView(item: item),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archive item?'),
          content: Text(
            '${item.title} will disappear from marketplace browsing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kDanger),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<ItemProvider>();
    await provider.archiveItem(item.id);
    if (!context.mounted) return;
    _showSnack(context, provider.errorMessage ?? 'Item archived.');
  }
}

class ResidentItemListingFormView extends StatefulWidget {
  const ResidentItemListingFormView({super.key, this.item});

  final ItemModel? item;

  @override
  State<ResidentItemListingFormView> createState() =>
      _ResidentItemListingFormViewState();
}

class _ResidentItemListingFormViewState
    extends State<ResidentItemListingFormView> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final List<XFile> _newPhotos = <XFile>[];

  String _category = AppConstants.itemCategoryTools;
  String _condition = AppConstants.itemConditionGood;
  ItemListingPricingType _pricingType = ItemListingPricingType.free;
  int _step = 0;
  bool _submitting = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) return;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _category = item.category;
    _condition = item.condition;
    _feeController.text = item.feeAmount == null
        ? ''
        : _amountText(item.feeAmount);
    _depositController.text = item.depositAmount == null
        ? ''
        : _amountText(item.depositAmount);
    _pickupController.text = item.pickupInstructions;
    _pricingType = _pricingTypeFromItem(item);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _depositController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  int get _photoCount =>
      (widget.item?.imageUrls.length ?? 0) + _newPhotos.length;

  @override
  Widget build(BuildContext context) {
    final sideInset = JiraniResponsive.scaled(context, 20);
    final title = _step == 0
        ? (_isEditing ? 'Edit Item' : 'Add New Item')
        : 'Financial Details';

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: JiraniBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: _step == 0 ? 'Back' : 'Item details',
                            onTap: _submitting
                                ? null
                                : () {
                                    if (_step == 0) {
                                      Navigator.of(context).pop();
                                    } else {
                                      setState(() => _step = 0);
                                    }
                                  },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kBrandTeal,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 56),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(sideInset, 10, sideInset, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _step == 0
                              ? _DetailsStep(
                                  key: const ValueKey('details'),
                                  titleController: _titleController,
                                  descriptionController: _descriptionController,
                                  existingImageUrls:
                                      widget.item?.imageUrls ?? const [],
                                  newPhotos: _newPhotos,
                                  category: _category,
                                  condition: _condition,
                                  onPickPhotos: _pickPhotos,
                                  onRemoveNewPhoto: (index) {
                                    setState(() => _newPhotos.removeAt(index));
                                  },
                                  onCategoryChanged: (value) {
                                    if (value != null) {
                                      setState(() => _category = value);
                                    }
                                  },
                                  onConditionChanged: (value) {
                                    if (value != null) {
                                      setState(() => _condition = value);
                                    }
                                  },
                                )
                              : _FinancialStep(
                                  key: const ValueKey('financial'),
                                  pricingType: _pricingType,
                                  feeController: _feeController,
                                  depositController: _depositController,
                                  pickupController: _pickupController,
                                  onPricingTypeChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _pricingType = value;
                                      if (!value.requiresFee) {
                                        _feeController.clear();
                                      }
                                      if (!value.requiresDeposit) {
                                        _depositController.clear();
                                      }
                                    });
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SecondaryButton(
                                label: 'Cancel',
                                icon: Icons.close_rounded,
                                onTap: _submitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PrimaryButton(
                                label: _step == 0
                                    ? 'Next'
                                    : _submitting
                                    ? 'Saving...'
                                    : _isEditing
                                    ? 'Save Item'
                                    : 'List Item',
                                icon: _step == 0
                                    ? Icons.arrow_forward_rounded
                                    : Icons.inventory_2_rounded,
                                onTap: _submitting
                                    ? null
                                    : _step == 0
                                    ? _goToFinancialStep
                                    : _submit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final remaining = _kMaxPhotos - _photoCount;
    if (remaining <= 0) {
      _showSnack(context, 'You can upload up to $_kMaxPhotos photos.');
      return;
    }
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1440,
      maxHeight: 1440,
      imageQuality: 84,
    );
    if (picked.isEmpty) return;
    setState(() {
      _newPhotos.addAll(picked.take(remaining));
    });
    if (picked.length > remaining && mounted) {
      _showSnack(context, 'Only $remaining more photos were added.');
    }
  }

  void _goToFinancialStep() {
    final error = ItemListingFormValidator.validateDetails(
      title: _titleController.text,
      category: _category,
      condition: _condition,
      description: _descriptionController.text,
      imageCount: _photoCount,
    );
    if (error != null) {
      _showSnack(context, error);
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      _showSnack(context, 'Sign in before listing an item.');
      return;
    }
    if (!user.isVerifiedResident) {
      _showSnack(
        context,
        'Only verified residents can list marketplace items.',
      );
      return;
    }

    final error = ItemListingFormValidator.validateFinancial(
      pricingType: _pricingType,
      feeText: _feeController.text,
      depositText: _depositController.text,
    );
    if (error != null) {
      _showSnack(context, error);
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<ItemProvider>();
    final fee = _pricingType.requiresFee
        ? ItemListingFormValidator.parseAmount(_feeController.text)
        : null;
    final deposit = _pricingType.requiresDeposit
        ? ItemListingFormValidator.parseAmount(_depositController.text)
        : null;
    final imagePaths = _newPhotos.map((photo) => photo.path).toList();

    if (_isEditing) {
      await provider.updateItem(
        itemId: widget.item!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        condition: _condition,
        hasUsageFee: _pricingType.requiresFee,
        feeAmount: fee,
        hasDeposit: _pricingType.requiresDeposit,
        depositAmount: deposit,
        pickupInstructions: _pickupController.text,
        newImagePaths: imagePaths.isEmpty ? null : imagePaths,
      );
    } else {
      await provider.addItem(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        condition: _condition,
        imagePaths: imagePaths,
        hasUsageFee: _pricingType.requiresFee,
        feeAmount: fee,
        hasDeposit: _pricingType.requiresDeposit,
        depositAmount: deposit,
        pickupInstructions: _pickupController.text,
        currentUser: user,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    final providerError = provider.errorMessage;
    if (providerError != null && providerError.isNotEmpty) {
      _showSnack(context, providerError.replaceFirst('Exception: ', ''));
      return;
    }
    _showSnack(context, _isEditing ? 'Item updated.' : 'Item listed.');
    Navigator.of(context).pop();
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.existingImageUrls,
    required this.newPhotos,
    required this.category,
    required this.condition,
    required this.onPickPhotos,
    required this.onRemoveNewPhoto,
    required this.onCategoryChanged,
    required this.onConditionChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<String> existingImageUrls;
  final List<XFile> newPhotos;
  final String category;
  final String condition;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemoveNewPhoto;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onConditionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Item Photos'),
        const SizedBox(height: 8),
        _PhotoPickerPanel(
          existingImageUrls: existingImageUrls,
          newPhotos: newPhotos,
          onPickPhotos: onPickPhotos,
          onRemoveNewPhoto: onRemoveNewPhoto,
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Item Details'),
        const SizedBox(height: 8),
        _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  label: 'Item Name',
                  hint: 'e.g. Book, Ladder...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: _inputDecoration(
                        label: 'Category',
                        hint: 'Select a category',
                      ),
                      items: _categoryOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: onCategoryChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: condition,
                      decoration: _inputDecoration(
                        label: 'Condition',
                        hint: 'Select condition',
                      ),
                      items: _conditionOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: onConditionChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                minLines: 5,
                maxLines: 7,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint:
                      'Describe the item, what is included, and any special rules for borrowing.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialStep extends StatelessWidget {
  const _FinancialStep({
    super.key,
    required this.pricingType,
    required this.feeController,
    required this.depositController,
    required this.pickupController,
    required this.onPricingTypeChanged,
  });

  final ItemListingPricingType pricingType;
  final TextEditingController feeController;
  final TextEditingController depositController;
  final TextEditingController pickupController;
  final ValueChanged<ItemListingPricingType?> onPricingTypeChanged;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<ItemListingPricingType>(
            initialValue: pricingType,
            decoration: _inputDecoration(
              label: 'Pricing Type',
              hint: 'Select a pricing type',
            ),
            items: ItemListingPricingType.values
                .map(
                  (type) => DropdownMenuItem<ItemListingPricingType>(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: onPricingTypeChanged,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MoneyField(
                  label: 'Borrowing Fee',
                  controller: feeController,
                  enabled: pricingType.requiresFee,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyField(
                  label: 'Deposit',
                  controller: depositController,
                  enabled: pricingType.requiresDeposit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pickupController,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(
              label: 'Pickup Instructions',
              hint: 'e.g. Meet at lobby after owner confirmation.',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Deposits are held securely and refunded to the borrower after a safe return.',
              style: TextStyle(
                color: _kMutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPickerPanel extends StatelessWidget {
  const _PhotoPickerPanel({
    required this.existingImageUrls,
    required this.newPhotos,
    required this.onPickPhotos,
    required this.onRemoveNewPhoto,
  });

  final List<String> existingImageUrls;
  final List<XFile> newPhotos;
  final VoidCallback onPickPhotos;
  final ValueChanged<int> onRemoveNewPhoto;

  int get _photoCount => existingImageUrls.length + newPhotos.length;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 212),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _photoCount == 0
                ? Colors.black.withValues(alpha: 0.30)
                : _kBrandTeal.withValues(alpha: 0.20),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _photoCount == 0
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CameraBadge(),
                  SizedBox(height: 12),
                  Text(
                    'Upload your Item (Up to 5)',
                    style: TextStyle(
                      color: _kInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to choose your photo.',
                    style: TextStyle(
                      color: _kMutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _CameraBadge(size: 42),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_photoCount of $_kMaxPhotos photos selected',
                          style: const TextStyle(
                            color: _kInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onPickPhotos,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 102,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photoCount,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index < existingImageUrls.length) {
                          return _PhotoThumb(url: existingImageUrls[index]);
                        }
                        final newIndex = index - existingImageUrls.length;
                        return _PhotoThumb(
                          localPath: newPhotos[newIndex].path,
                          onRemove: () => onRemoveNewPhoto(newIndex),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({this.url, this.localPath, this.onRemove});

  final String? url;
  final String? localPath;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (localPath != null && localPath!.isNotEmpty) {
      image = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      image = CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover);
    } else {
      image = const Icon(Icons.inventory_2_rounded, color: _kBrandTeal);
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 102,
            height: 102,
            color: _kBrandTeal.withValues(alpha: 0.08),
            child: image,
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 6,
            top: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.56),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFCFE5E9),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        color: Colors.black,
        size: size * 0.58,
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label: label, hint: '0.00').copyWith(
        prefixIcon: Container(
          width: 44,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: enabled ? 0.10 : 0.05),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
          ),
          child: Text(
            'RM',
            style: TextStyle(
              color: enabled ? _kInk : _kMutedText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileListingSummary extends StatelessWidget {
  const _ProfileListingSummary({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kBrandTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.storefront_rounded, color: _kBrandTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName.trim().isNotEmpty == true
                      ? '${user!.fullName} can lend items'
                      : 'List items for your neighbors',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Published items appear in marketplace for residents in your community.',
                  style: TextStyle(
                    color: _kMutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMyItemsCard extends StatelessWidget {
  const _EmptyMyItemsCard({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: _kBrandTeal, size: 46),
          const SizedBox(height: 12),
          const Text(
            'No items listed yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share tools, electronics, books, and household items with trusted neighbors.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'Add Item',
            icon: Icons.add_rounded,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _MyItemCard extends StatelessWidget {
  const _MyItemCard({
    required this.item,
    required this.onEdit,
    required this.onArchive,
  });

  final ItemModel item;
  final VoidCallback onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ItemThumb(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_categoryLabel(item.category)} · ${_conditionLabel(item.condition)}',
                      style: const TextStyle(
                        color: _kMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatusPill(label: _statusLabel(item)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.hasUsageFee ? _money(item.feeAmount) : 'Free',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kBrandTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DangerButton(
                  label: item.isArchived ? 'Archived' : 'Archive',
                  icon: Icons.archive_outlined,
                  onTap: onArchive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 82,
        height: 82,
        color: _kBrandTeal.withValues(alpha: 0.10),
        child: imageUrl.isEmpty
            ? const Icon(Icons.inventory_2_rounded, color: _kBrandTeal)
            : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: _kBrandTeal, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(
          JiraniResponsive.scaledRadius(context, 22),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: JiraniResponsive.scaled(context, 24),
            offset: Offset(0, JiraniResponsive.scaled(context, 12)),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _InsetContent extends StatelessWidget {
  const _InsetContent({required this.sideInset, required this.child});

  final double sideInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sideInset),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: child,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _kInk,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? const Color(0xFF9CA3AF) : _kBrandTeal,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _kBrandTeal, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled ? const Color(0xFFF3F4F6) : _DangerColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: disabled ? const Color(0xFFE5E7EB) : _kDanger,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: disabled ? _kMutedText : _kDanger, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? _kMutedText : _kDanger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerColors {
  static const Color surface = Color(0xFFFFF1F2);
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.90),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: onTap == null ? _kMutedText : _kInk),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final archived = label == 'Archived';
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: archived
            ? _kMutedText.withValues(alpha: 0.12)
            : _kBrandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: archived ? _kMutedText : _kBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Option {
  const _Option(this.label, this.value);

  final String label;
  final String value;
}

const List<_Option> _categoryOptions = [
  _Option('Tools', AppConstants.itemCategoryTools),
  _Option('Kitchen', AppConstants.itemCategoryKitchen),
  _Option('Electronics', AppConstants.itemCategoryElectronics),
  _Option('Cleaning', AppConstants.itemCategoryCleaning),
  _Option('Study', AppConstants.itemCategoryStudy),
  _Option('Event Items', AppConstants.itemCategoryEventItems),
  _Option('Other', AppConstants.itemCategoryOther),
];

const List<_Option> _conditionOptions = [
  _Option('New', AppConstants.itemConditionNew),
  _Option('Good', AppConstants.itemConditionGood),
  _Option('Used', AppConstants.itemConditionUsed),
];

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _kBrandTeal, width: 1.4),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
  );
}

ItemListingPricingType _pricingTypeFromItem(ItemModel item) {
  if (item.hasUsageFee && item.hasDeposit) {
    return ItemListingPricingType.feeAndDeposit;
  }
  if (item.hasUsageFee) return ItemListingPricingType.feeOnly;
  if (item.hasDeposit) return ItemListingPricingType.depositOnly;
  return ItemListingPricingType.free;
}

String _amountText(double? amount) {
  if (amount == null) return '';
  return amount % 1 == 0
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

String _money(double? amount) {
  return 'RM ${_amountText(amount ?? 0)}';
}

String _categoryLabel(String category) {
  for (final option in _categoryOptions) {
    if (option.value == category) return option.label;
  }
  return 'Other';
}

String _conditionLabel(String condition) {
  for (final option in _conditionOptions) {
    if (option.value == condition) return option.label;
  }
  return 'Used';
}

String _statusLabel(ItemModel item) {
  if (item.isArchived || item.status == AppConstants.itemStatusArchived) {
    return 'Archived';
  }
  if (item.status == AppConstants.itemStatusAvailable) return 'Available';
  if (item.status == AppConstants.itemStatusUnavailable) return 'Unavailable';
  if (item.status == AppConstants.itemStatusBorrowed) return 'Borrowed';
  return item.status;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

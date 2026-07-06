part of '../resident_item_listing_view.dart';

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
    const titleSize = 20.0;

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
                            icon: Icons.chevron_left_rounded,
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
                              style: TextStyle(
                                color: _kBrandTeal,
                                fontSize: titleSize,
                                fontWeight: _step == 0
                                    ? FontWeight.w900
                                    : FontWeight.w800,
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
                decoration: context.residentInputDecoration(
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
                      isExpanded: true,
                      decoration: context.residentInputDecoration(
                        label: 'Category',
                        hint: 'Select a category',
                      ),
                      items: _categoryOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                      isExpanded: true,
                      decoration: context.residentInputDecoration(
                        label: 'Condition',
                        hint: 'Select condition',
                      ),
                      items: _conditionOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                decoration: context.residentInputDecoration(
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
            isExpanded: true,
            decoration: context.residentInputDecoration(
              label: 'Pricing Type',
              hint: 'Select a pricing type',
            ),
            items: ItemListingPricingType.values
                .map(
                  (type) => DropdownMenuItem<ItemListingPricingType>(
                    value: type,
                    child: Text(
                      type.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  label: 'Daily Fee',
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
            decoration: context.residentInputDecoration(
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
            child: Text(
              'Set the daily fee. Hourly borrowing is calculated automatically from this price and capped at the daily rate.',
              style: TextStyle(
                color: context.appMuted,
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
    final ink = context.appInk;
    final muted = context.appMuted;
    final isDark = context.isDarkUi;

    return InkWell(
      onTap: onPickPhotos,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 212),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.glassFill( lightAlpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _photoCount == 0
                ? (isDark
                      ? Theme.of(context).colorScheme.outlineVariant
                      : Colors.black.withValues(alpha: 0.30))
                : _kBrandTeal.withValues(alpha: 0.20),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _photoCount == 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _CameraBadge(),
                  const SizedBox(height: 12),
                  Text(
                    'Upload your Item (Up to 5)',
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose your photo.',
                    style: TextStyle(
                      color: muted,
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
                          style: TextStyle(
                            color: ink,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.avatarPlaceholder,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.photo_camera_rounded,
        color: scheme.onPrimaryContainer,
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
      decoration: context.residentInputDecoration(label: label, hint: '0.00').copyWith(
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
              color: enabled ? context.appInk : context.appMuted,
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
                  style: TextStyle(
                    color: context.appInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Published items appear in marketplace for residents in your community.',
                  style: TextStyle(
                    color: context.appMuted,
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


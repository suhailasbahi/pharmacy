import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/region_pricing.dart';
import '../../models/bonus_model.dart';
import '../../models/region.dart';
import '../../providers/product_provider.dart';

// نموذج مجموعة الأسعار
class _PriceGroup {
  double price;
  String currency;
  double taxRate;
  List<Region> regions;
  bool hasOffer;
  double? offerPrice;

  _PriceGroup({
    required this.price,
    required this.currency,
    required this.taxRate,
    required this.regions,
    this.hasOffer = false,
    this.offerPrice,
  });
}

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  final String agencyId;
  const EditProductScreen({Key? key, required this.product, required this.agencyId}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _scientificNameController;
  late TextEditingController _concentrationController;
  late TextEditingController _stockController;
  late TextEditingController _minOrderController;
  late bool _requiresCooling;
  late DateTime _expiryDate;
  bool _isLoading = false;
  File? _selectedImage;
  late String _defaultUnit;
  late TextEditingController _pricePerPieceController;
  late TextEditingController _pricePerCartonController;
  late TextEditingController _piecesPerCartonController;
  late BonusModel? _bonusCash;
  late BonusModel? _bonusCredit;
  final ImagePicker _picker = ImagePicker();
  
  List<_PriceGroup> _priceGroups = [];
  final List<Region> _allRegions = Region.allRegions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _scientificNameController = TextEditingController(text: widget.product.scientificName);
    _concentrationController = TextEditingController(text: widget.product.concentration);
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _minOrderController = TextEditingController(text: widget.product.minOrderQuantity.toString());
    _requiresCooling = widget.product.requiresCooling;
    _expiryDate = widget.product.expiryDate;
    _defaultUnit = widget.product.defaultUnit;
    _pricePerPieceController = TextEditingController(text: widget.product.pricePerPiece.toString());
    _pricePerCartonController = TextEditingController(text: widget.product.pricePerCarton.toString());
    _piecesPerCartonController = TextEditingController(text: widget.product.piecesPerCarton.toString());
    _bonusCash = widget.product.bonusCash;
    _bonusCredit = widget.product.bonusCredit;
    
    _loadRegionPriceGroups(widget.product.regionPrices);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _concentrationController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _pricePerPieceController.dispose();
    _pricePerCartonController.dispose();
    _piecesPerCartonController.dispose();
    super.dispose();
  }

  // ========== دوال تسعير المحافظات ==========
  
  void _loadRegionPriceGroups(List<RegionPricing> existingPrices) {
    final Map<String, _PriceGroup> groupMap = {};
    
    for (var pricing in existingPrices) {
      final key = '${pricing.price}_${pricing.currency}_${pricing.taxRate}_${pricing.hasOffer}_${pricing.offerPrice}';
      
      if (!groupMap.containsKey(key)) {
        groupMap[key] = _PriceGroup(
          price: pricing.price,
          currency: pricing.currency,
          taxRate: pricing.taxRate,
          regions: [],
          hasOffer: pricing.hasOffer,
          offerPrice: pricing.offerPrice,
        );
      }
      
      final region = _allRegions.firstWhere(
        (r) => r.id == pricing.regionId,
        orElse: () => Region(pricing.regionId, pricing.regionName),
      );
      
      groupMap[key]!.regions.add(region);
    }
    
    _priceGroups = groupMap.values.toList();
  }

  List<Region> _getUnassignedRegions() {
    final selectedRegionIds = _priceGroups
        .expand((group) => group.regions.map((r) => r.id))
        .toSet();
    return _allRegions.where((region) => !selectedRegionIds.contains(region.id)).toList();
  }

  List<Region> _getUnassignedRegionsForDialog(List<Region> currentSelected) {
    final otherSelectedIds = _priceGroups
        .expand((g) => g.regions.map((r) => r.id))
        .where((id) => !currentSelected.map((r) => r.id).contains(id))
        .toSet();
    return _allRegions.where((region) => 
      !otherSelectedIds.contains(region.id) || currentSelected.contains(region)
    ).toList();
  }

  void _showAddPriceDialog({_PriceGroup? existingGroup, int? editIndex}) {
    final priceController = TextEditingController(
      text: existingGroup?.price.toString() ?? '',
    );
    final taxController = TextEditingController(
      text: existingGroup?.taxRate.toString() ?? '',
    );
    final offerPriceController = TextEditingController(
      text: existingGroup?.offerPrice?.toString() ?? '',
    );
    
    String selectedCurrency = existingGroup?.currency ?? 'yemen';
    bool hasOffer = existingGroup?.hasOffer ?? false;
    List<Region> selectedRegions = existingGroup?.regions != null 
        ? List.from(existingGroup!.regions) 
        : [];
    
    List<Region> availableRegions = _getUnassignedRegionsForDialog(selectedRegions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(editIndex != null ? 'تعديل مجموعة الأسعار' : 'إضافة سعر جديد'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر الأساسي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCurrency,
                    decoration: const InputDecoration(labelText: 'العملة'),
                    items: const [
                      DropdownMenuItem(value: 'yemen', child: Text('ريال يمني')),
                      DropdownMenuItem(value: 'saudi', child: Text('ريال سعودي')),
                      DropdownMenuItem(value: 'dollar', child: Text('دولار')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCurrency = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الضريبة (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('تفعيل عرض خاص لهذه المحافظات'),
                    value: hasOffer,
                    onChanged: (val) => setDialogState(() => hasOffer = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasOffer)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: offerPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سعر العرض',
                          border: OutlineInputBorder(),
                          helperText: 'السعر بعد الخصم لهذه المحافظات',
                        ),
                      ),
                    ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('اختر المحافظات:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: availableRegions.length,
                      itemBuilder: (_, i) {
                        final region = availableRegions[i];
                        final isSelected = selectedRegions.contains(region);
                        return CheckboxListTile(
                          title: Text(region.name),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedRegions.add(region);
                              } else {
                                selectedRegions.remove(region);
                              }
                            });
                          },
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(priceController.text) ?? 0;
                  if (price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال سعر صحيح'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  if (selectedRegions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى اختيار محافظة واحدة على الأقل'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  
                  final offerPrice = hasOffer ? double.tryParse(offerPriceController.text) : null;
                  if (hasOffer && (offerPrice == null || offerPrice <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال سعر عرض صحيح'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  
                  setState(() {
                    final newGroup = _PriceGroup(
                      price: price,
                      currency: selectedCurrency,
                      taxRate: double.tryParse(taxController.text) ?? 0,
                      regions: selectedRegions,
                      hasOffer: hasOffer,
                      offerPrice: offerPrice,
                    );
                    
                    if (editIndex != null) {
                      _priceGroups[editIndex] = newGroup;
                    } else {
                      _priceGroups.add(newGroup);
                    }
                  });
                  
                  Navigator.pop(ctx);
                },
                child: Text(editIndex != null ? 'حفظ' : 'إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editPriceGroup(_PriceGroup group, int index) {
    _showAddPriceDialog(existingGroup: group, editIndex: index);
  }

  void _removePriceGroup(int index) {
    setState(() {
      _priceGroups.removeAt(index);
    });
  }

  List<RegionPricing> _convertToRegionPricing() {
    final List<RegionPricing> result = [];
    for (var group in _priceGroups) {
      for (var region in group.regions) {
        result.add(RegionPricing(
          regionId: region.id,
          regionName: region.name,
          price: group.price,
          currency: group.currency,
          taxRate: group.taxRate,
          hasOffer: group.hasOffer,
          offerPrice: group.offerPrice,
        ));
      }
    }
    return result;
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'yemen': return 'ر.ي';
      case 'saudi': return 'ر.س';
      case 'dollar': return '\$';
      default: return 'ر.ي';
    }
  }

  Widget _buildPriceGroupCard(_PriceGroup group, int index) {
    final currencySymbol = _getCurrencySymbol(group.currency);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: group.hasOffer ? Colors.red.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${group.price.toStringAsFixed(2)} $currencySymbol',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    if (group.hasOffer && group.offerPrice != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'عرض: ${group.offerPrice!.toStringAsFixed(2)} $currencySymbol',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editPriceGroup(group, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePriceGroup(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('ضريبة: ${group.taxRate}%', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: group.regions.map((r) => Chip(
                label: Text(r.name),
                backgroundColor: group.hasOffer ? Colors.red.shade100 : Colors.teal.shade50,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionPricingSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('تسعير المناطق والعروض', style: TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddPriceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سعر جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                const SizedBox(height: 12),
                ..._priceGroups.asMap().entries.map((entry) {
                  return _buildPriceGroupCard(entry.value, entry.key);
                }),
                if (_priceGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد أسعار محددة', style: TextStyle(color: Colors.grey)),
                  ),
                if (_getUnassignedRegions().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ محافظات غير مسعرة: ${_getUnassignedRegions().map((r) => r.name).join(', ')}',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== دوال أخرى ==========

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _updateProduct() {
    if (!_formKey.currentState!.validate()) return;
    if (_priceGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة تسعير للمناطق'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    final updatedProduct = ProductModel(
      id: widget.product.id,
      companyId: widget.product.companyId,
      companyName: widget.product.companyName,
      agencyId: widget.agencyId,
      name: _nameController.text.trim(),
      scientificName: _scientificNameController.text.trim(),
      concentration: _concentrationController.text.trim(),
      stockQuantity: int.parse(_stockController.text),
      requiresCooling: _requiresCooling,
      imageUrl: _selectedImage?.path ?? widget.product.imageUrl,
      expiryDate: _expiryDate,
      isActive: true,
      createdAt: widget.product.createdAt,
      regionPrices: _convertToRegionPricing(),
      hasOffer: false,
      offerPrice: null,
      bonusCash: _bonusCash,
      bonusCredit: _bonusCredit,
      pricePerPiece: double.tryParse(_pricePerPieceController.text) ?? 0,
      pricePerCarton: double.tryParse(_pricePerCartonController.text) ?? 0,
      piecesPerCarton: int.tryParse(_piecesPerCartonController.text) ?? 1,
      defaultUnit: _defaultUnit,
      minOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
      createdBy: widget.product.createdBy,
      branchId: widget.product.branchId,
    );

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.updateProduct(updatedProduct).then((_) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل المنتج بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }).catchError((e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'الاسم التجاري', Icons.medication),
              const SizedBox(height: 16),
              _buildTextField(_scientificNameController, 'الاسم العلمي', Icons.science),
              const SizedBox(height: 16),
              _buildTextField(_concentrationController, 'التركيز', Icons.straighten),
              const SizedBox(height: 16),
              _buildNumberField(_stockController, 'الكمية المتاحة', Icons.inventory),
              const SizedBox(height: 16),
              _buildMinOrderField(),
              const SizedBox(height: 16),
              _buildUnitDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_pricePerPieceController, 'سعر الباكيت', Icons.currency_bitcoin, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_pricePerCartonController, 'سعر الكرتون', Icons.inventory, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(_piecesPerCartonController, 'عدد الباكيتات في الكرتون', Icons.view_agenda, isNumber: true),
              const SizedBox(height: 16),
              _buildRegionPricingSection(),
              const SizedBox(height: 16),
              _buildBonusesSection(),
              const SizedBox(height: 16),
              _buildExpiryDatePicker(),
              const SizedBox(height: 16),
              _buildCoolingSwitch(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ========== واجهات المستخدم ==========
  
  Widget _buildTextField(TextEditingController c, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
    );
  }

  Widget _buildNumberField(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
    );
  }

  Widget _buildMinOrderField() {
    return TextFormField(
      controller: _minOrderController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'الحد الأدنى للطلب (بالباكيت)',
        prefixIcon: const Icon(Icons.low_priority),
        suffixText: 'باكيت',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _defaultUnit,
          items: const [
            DropdownMenuItem(value: 'piece', child: Text('باكيت')),
            DropdownMenuItem(value: 'carton', child: Text('كرتون')),
          ],
          onChanged: (value) => setState(() => _defaultUnit = value!),
        ),
      ),
    );
  }

  Widget _buildBonusesSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('البونص (نقدي وآجل)', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ListTile(
            title: const Text('بونص على الطلبات النقدية'),
            subtitle: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'النسبة المئوية (مثال: 10)'),
              onChanged: (val) {
                double p = double.tryParse(val) ?? 0;
                setState(() {
                  _bonusCash = p > 0 ? BonusModel(percentage: p, forCashOnly: true) : null;
                });
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('بونص على الطلبات الآجلة'),
            subtitle: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'النسبة المئوية (مثال: 5)'),
              onChanged: (val) {
                double p = double.tryParse(val) ?? 0;
                setState(() {
                  _bonusCredit = p > 0 ? BonusModel(percentage: p, forCashOnly: false) : null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryDatePicker() {
    return InkWell(
      onTap: _selectExpiryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, color: Colors.teal),
          const SizedBox(width: 12),
          Text('تاريخ الصلاحية: ${_expiryDate.year}-${_expiryDate.month}-${_expiryDate.day}'),
        ]),
      ),
    );
  }

  Widget _buildCoolingSwitch() {
    return SwitchListTile(
      title: const Text('يحتاج تبريد'),
      value: _requiresCooling,
      onChanged: (v) => setState(() => _requiresCooling = v),
      activeColor: Colors.teal,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _selectedImage != null
            ? Image.file(_selectedImage!, fit: BoxFit.cover)
            : (widget.product.imageUrl != null
                ? Image.file(File(widget.product.imageUrl!), fit: BoxFit.cover)
                : const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProduct,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('حفظ التعديلات'),
      ),
    );
  }
}
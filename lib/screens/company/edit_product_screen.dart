import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../models/region_pricing.dart';
import '../../models/bonus_model.dart';
import '../../models/agency_model.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  final AgencyModel agency;
  const EditProductScreen({Key? key, required this.product, required this.agency}) : super(key: key);

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
  late bool _hasOffer;
  late TextEditingController _offerPriceController;
  late String _defaultUnit;
  late TextEditingController _pricePerPieceController;
  late TextEditingController _pricePerCartonController;
  late TextEditingController _piecesPerCartonController;
  late List<RegionPricing> _regionPrices;
  late BonusModel? _bonusCash;
  late BonusModel? _bonusCredit;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> regions = [
    {'id': 'sanaa', 'name': 'صنعاء'}, {'id': 'aden', 'name': 'عدن'}, {'id': 'taiz', 'name': 'تعز'}, {'id': 'hodeidah', 'name': 'الحديدة'}, {'id': 'ibb', 'name': 'إب'}, {'id': 'mukalla', 'name': 'المكلا'}, {'id': 'sayun', 'name': 'سيئون'},
  ];

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
    _hasOffer = widget.product.hasOffer;
    _offerPriceController = TextEditingController(text: widget.product.offerPrice?.toString() ?? '');
    _defaultUnit = widget.product.defaultUnit;
    _pricePerPieceController = TextEditingController(text: widget.product.pricePerPiece.toString());
    _pricePerCartonController = TextEditingController(text: widget.product.pricePerCarton.toString());
    _piecesPerCartonController = TextEditingController(text: widget.product.piecesPerCarton.toString());
    _regionPrices = List.from(widget.product.regionPrices);
    _bonusCash = widget.product.bonusCash;
    _bonusCredit = widget.product.bonusCredit;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _expiryDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825)));
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _updateProduct() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final updatedProduct = ProductModel(
      id: widget.product.id,
      companyId: widget.product.companyId,
      companyName: widget.product.companyName,
      name: _nameController.text.trim(),
      scientificName: _scientificNameController.text.trim(),
      concentration: _concentrationController.text.trim(),
      stockQuantity: int.parse(_stockController.text),
      requiresCooling: _requiresCooling,
      imageUrl: _selectedImage?.path ?? widget.product.imageUrl,
      expiryDate: _expiryDate,
      isActive: true,
      createdAt: widget.product.createdAt,
      regionPrices: _regionPrices,
      hasOffer: _hasOffer,
      offerPrice: double.tryParse(_offerPriceController.text),
      bonusCash: _bonusCash,
      bonusCredit: _bonusCredit,
      pricePerPiece: double.tryParse(_pricePerPieceController.text) ?? 0,
      pricePerCarton: double.tryParse(_pricePerCartonController.text) ?? 0,
      piecesPerCarton: int.tryParse(_piecesPerCartonController.text) ?? 1,
      defaultUnit: _defaultUnit,
      minOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
    );

    final index = widget.agency.products.indexWhere((p) => p.id == widget.product.id);
    if (index != -1) widget.agency.products[index] = updatedProduct;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعديل المنتج بنجاح'), backgroundColor: Colors.green));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تعديل المنتج'), centerTitle: true, backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              SizedBox(height: 16),
              _buildTextField(_nameController, 'الاسم التجاري', Icons.medication),
              SizedBox(height: 16),
              _buildTextField(_scientificNameController, 'الاسم العلمي', Icons.science),
              SizedBox(height: 16),
              _buildTextField(_concentrationController, 'التركيز', Icons.straighten),
              SizedBox(height: 16),
              _buildNumberField(_stockController, 'الكمية المتاحة', Icons.inventory),
              SizedBox(height: 16),
              _buildMinOrderField(),
              SizedBox(height: 16),
              _buildUnitDropdown(),
              SizedBox(height: 16),
              _buildTextField(_pricePerPieceController, 'سعر الباكيت', Icons.currency_bitcoin, isNumber: true),
              SizedBox(height: 16),
              _buildTextField(_pricePerCartonController, 'سعر الكرتون', Icons.inventory, isNumber: true),
              SizedBox(height: 16),
              _buildTextField(_piecesPerCartonController, 'عدد الباكيتات في الكرتون', Icons.view_agenda, isNumber: true),
              SizedBox(height: 16),
              _buildRegionPricingTable(),
              SizedBox(height: 16),
              _buildBonusesSection(),
              SizedBox(height: 16),
              _buildExpiryDatePicker(),
              SizedBox(height: 16),
              _buildCoolingSwitch(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon, {bool isNumber = false}) => TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
      );

  Widget _buildNumberField(TextEditingController c, String label, IconData icon) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (v) => v!.isEmpty ? 'أدخل $label' : null,
      );

  Widget _buildMinOrderField() => TextFormField(
        controller: _minOrderController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'الحد الأدنى للطلب (بالباكيت)', prefixIcon: Icon(Icons.low_priority), suffixText: 'باكيت', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      );

  Widget _buildUnitDropdown() => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _defaultUnit,
            items: const [DropdownMenuItem(value: 'piece', child: Text('باكيت')), DropdownMenuItem(value: 'carton', child: Text('كرتون'))],
            onChanged: (value) => setState(() => _defaultUnit = value!),
          ),
        ),
      );

  Widget _buildRegionPricingTable() {
    return Card(
      child: ExpansionTile(
        title: Text('تسعير المناطق', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [DataColumn(label: Text('المنطقة')), DataColumn(label: Text('السعر')), DataColumn(label: Text('العملة')), DataColumn(label: Text('الضريبة %'))],
              rows: _regionPrices.map((rp) {
                int idx = _regionPrices.indexOf(rp);
                return DataRow(cells: [
                  DataCell(Text(rp.regionName)),
                  DataCell(TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'السعر'),
                    onChanged: (val) {
                      double price = double.tryParse(val) ?? 0;
                      setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: price, currency: rp.currency, taxRate: rp.taxRate));
                    },
                  )),
                  DataCell(DropdownButton<String>(
                    value: rp.currency,
                    items: const [DropdownMenuItem(value: 'yemen', child: Text('ريال يمني')), DropdownMenuItem(value: 'saudi', child: Text('ريال سعودي')), DropdownMenuItem(value: 'dollar', child: Text('دولار'))],
                    onChanged: (val) => setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: rp.price, currency: val!, taxRate: rp.taxRate)),
                  )),
                  DataCell(TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '%'),
                    onChanged: (val) {
                      double tax = double.tryParse(val) ?? 0;
                      setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: rp.price, currency: rp.currency, taxRate: tax));
                    },
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusesSection() => Card(
        child: ExpansionTile(
          title: Text('البونص (نقدي وآجل)', style: TextStyle(fontWeight: FontWeight.bold)),
          children: [
            ListTile(
              title: Text('بونص على الطلبات النقدية'),
              subtitle: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'النسبة المئوية (مثال: 10)'),
                onChanged: (val) {
                  double p = double.tryParse(val) ?? 0;
                  setState(() => _bonusCash = p > 0 ? BonusModel(percentage: p, forCashOnly: true) : null);
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text('بونص على الطلبات الآجلة'),
              subtitle: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'النسبة المئوية (مثال: 5)'),
                onChanged: (val) {
                  double p = double.tryParse(val) ?? 0;
                  setState(() => _bonusCredit = p > 0 ? BonusModel(percentage: p, forCashOnly: false) : null);
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildExpiryDatePicker() => InkWell(
        onTap: _selectExpiryDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.calendar_today, color: Colors.teal),
            const SizedBox(width: 12),
            Text('تاريخ الصلاحية: ${_expiryDate.year}-${_expiryDate.month}-${_expiryDate.day}'),
          ]),
        ),
      );

  Widget _buildCoolingSwitch() => SwitchListTile(title: const Text('يحتاج تبريد'), value: _requiresCooling, onChanged: (v) => setState(() => _requiresCooling = v));

  Widget _buildImagePicker() => GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : (widget.product.imageUrl != null ? Image.file(File(widget.product.imageUrl!), fit: BoxFit.cover) : Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey)),
        ),
      );
  
  Widget _buildSubmitButton() => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _updateProduct, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ التعديلات')));
}
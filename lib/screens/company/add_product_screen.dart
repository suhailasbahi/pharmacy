import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../models/region_pricing.dart';
import '../../models/bonus_model.dart';
import '../../models/dummy_products.dart';
import '../../models/agency_model.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AddProductScreen extends StatefulWidget {
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _concentrationController = TextEditingController();
  final _stockController = TextEditingController();
  final _minOrderController = TextEditingController();
  bool _requiresCooling = false;
  DateTime? _expiryDate;
  bool _isLoading = false;
  File? _selectedImage;
  bool _hasOffer = false;
  final _offerPriceController = TextEditingController();
  String _defaultUnit = 'piece';
  final _pricePerPieceController = TextEditingController();
  final _pricePerCartonController = TextEditingController();
  final _piecesPerCartonController = TextEditingController();
  List<RegionPricing> _regionPrices = [];
  BonusModel? _bonusCash;
  BonusModel? _bonusCredit;
  AgencyModel? _selectedAgency;
  List<AgencyModel> _agencies = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> regions = [
    {'id': 'sanaa', 'name': 'صنعاء'},
    {'id': 'aden', 'name': 'عدن'},
    {'id': 'taiz', 'name': 'تعز'},
    {'id': 'hodeidah', 'name': 'الحديدة'},
    {'id': 'ibb', 'name': 'إب'},
    {'id': 'mukalla', 'name': 'المكلا'},
    {'id': 'sayun', 'name': 'سيئون'},
  ];

  @override
  void initState() {
    super.initState();
    _agencies = dummyAgencies.where((a) => a.companyId == 'comp_001').toList();
    _regionPrices = regions.map((reg) => RegionPricing(regionId: reg['id']!, regionName: reg['name']!, price: 0, currency: 'yemen')).toList();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImage = File(image.path));
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _addProduct() {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      _showSnackBar('يرجى اختيار تاريخ الصلاحية', Colors.orange);
      return;
    }
    if (_selectedAgency == null) {
      _showSnackBar('يرجى اختيار الوكالة', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
      
    final auth = Provider.of<AuthService>(context, listen: false);
    final newProduct = ProductModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: 'comp_001',
      companyName: 'شركة الأدوية العربية',
      name: _nameController.text.trim(),
      scientificName: _scientificNameController.text.trim(),
      concentration: _concentrationController.text.trim(),
      stockQuantity: int.parse(_stockController.text),
      requiresCooling: _requiresCooling,
      imageUrl: _selectedImage?.path,
      expiryDate: _expiryDate!,
      isActive: true,
      createdAt: DateTime.now(),
      regionPrices: _regionPrices,
      bonusCash: _bonusCash,
      bonusCredit: _bonusCredit,
      pricePerPiece: double.tryParse(_pricePerPieceController.text) ?? 0,
      pricePerCarton: double.tryParse(_pricePerCartonController.text) ?? 0,
      piecesPerCarton: int.tryParse(_piecesPerCartonController.text) ?? 1,
      defaultUnit: _defaultUnit,
      minOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
      hasOffer: _hasOffer,
      offerPrice: _hasOffer ? double.tryParse(_offerPriceController.text) : null,
        createdBy:  auth.currentUserId,
    );

    _selectedAgency!.products.add(newProduct);
    setState(() => _isLoading = false);
    _showSnackBar('تم إضافة المنتج بنجاح', Colors.green);
    _clearForm();
  }

  void _clearForm() {
    _nameController.clear();
    _scientificNameController.clear();
    _concentrationController.clear();
    _stockController.clear();
    _minOrderController.clear();
    _offerPriceController.clear();
    _pricePerPieceController.clear();
    _pricePerCartonController.clear();
    _piecesPerCartonController.clear();
    setState(() {
      _requiresCooling = false;
      _expiryDate = null;
      _selectedAgency = null;
      _hasOffer = false;
      _selectedImage = null;
      _defaultUnit = 'piece';
      _bonusCash = null;
      _bonusCredit = null;
      _regionPrices = regions.map((reg) => RegionPricing(regionId: reg['id']!, regionName: reg['name']!, price: 0, currency: 'yemen')).toList();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة دواء جديد'),
                     automaticallyImplyLeading: false,
                     centerTitle: true, backgroundColor: Colors.teal),
     
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAgencyDropdown(),
              SizedBox(height: 16),
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
              _buildOfferSection(),
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

  Widget _buildOfferSection() {
    return Card(
      child: ExpansionTile(
        title: Text('عرض خاص', style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          SwitchListTile(
            title: Text('تفعيل عرض خاص'),
            value: _hasOffer,
            onChanged: (val) => setState(() => _hasOffer = val),
          ),
          if (_hasOffer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _offerPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر العرض (وحدة البيع الافتراضية)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgencyDropdown() => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AgencyModel>(
            value: _selectedAgency,
            hint: const Text('اختر الوكالة'),
            isExpanded: true,
            items: _agencies.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
            onChanged: (value) => setState(() => _selectedAgency = value),
          ),
        ),
      );

  Widget _buildImagePicker() => GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: _selectedImage != null
              ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('اضغط لإضافة صورة', style: TextStyle(color: Colors.grey)),
                ]),
        ),
      );

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
        decoration: InputDecoration(
          labelText: 'الحد الأدنى للطلب (بالباكيت)',
          prefixIcon: Icon(Icons.low_priority),
          suffixText: 'باكيت',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
                    onChanged: (val) => setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: double.tryParse(val) ?? 0, currency: rp.currency, taxRate: rp.taxRate)),
                  )),
                  DataCell(DropdownButton<String>(
                    value: rp.currency,
                    items: const [DropdownMenuItem(value: 'yemen', child: Text('ريال يمني')), DropdownMenuItem(value: 'saudi', child: Text('ريال سعودي')), DropdownMenuItem(value: 'dollar', child: Text('دولار'))],
                    onChanged: (val) => setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: rp.price, currency: val!, taxRate: rp.taxRate)),
                  )),
                  DataCell(TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: '%'),
                    onChanged: (val) => setState(() => _regionPrices[idx] = RegionPricing(regionId: rp.regionId, regionName: rp.regionName, price: rp.price, currency: rp.currency, taxRate: double.tryParse(val) ?? 0)),
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
            Text(_expiryDate == null ? 'اختر تاريخ الصلاحية' : 'تاريخ الصلاحية: ${_expiryDate!.year}-${_expiryDate!.month}-${_expiryDate!.day}'),
          ]),
        ),
      );

  Widget _buildCoolingSwitch() => SwitchListTile(
        title: const Text('يحتاج تبريد'),
        value: _requiresCooling,
        onChanged: (v) => setState(() => _requiresCooling = v),
        activeColor: Colors.teal,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      );

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _addProduct,
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('إضافة المنتج', style: TextStyle(fontSize: 18)),
        ),
      );
}
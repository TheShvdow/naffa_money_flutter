import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
final UserModel user;
const ProfileScreen({Key? key, required this.user}) : super(key: key);

@override
_ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
final _formKey = GlobalKey<FormState>();
late TextEditingController _nameController;
late TextEditingController _phoneController;
late TextEditingController _emailController;
late TextEditingController _currentPasswordController;
late TextEditingController _newPasswordController;
File? _imageFile;
bool _isLoading = false;

@override
void initState() {
super.initState();
_nameController = TextEditingController(text: widget.user.name);
_phoneController = TextEditingController(text: widget.user.phone);
_emailController = TextEditingController(text: widget.user.email);
_currentPasswordController = TextEditingController();
_newPasswordController = TextEditingController();
}

Future<void> _pickImage() async {
try {
final XFile? image = await ImagePicker().pickImage(
source: ImageSource.gallery,
maxWidth: 512,
maxHeight: 512,
imageQuality: 75,
);

if (image != null) {
setState(() {
_imageFile = File(image.path);
});
}
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Erreur lors de la sélection de l\'image: $e'),
backgroundColor: Colors.red,
),
);
}
}

Future<String?> _uploadImage() async {
if (_imageFile == null) return null;

try {
final String fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
final Reference ref = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');

await ref.putFile(_imageFile!);
return await ref.getDownloadURL();
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Erreur lors de l\'upload de l\'image: $e'),
backgroundColor: Colors.red,
),
);
return null;
}
}

Future<void> _updateProfile() async {
if (!_formKey.currentState!.validate()) return;

setState(() => _isLoading = true);

try {
String? imageUrl;
if (_imageFile != null) {
imageUrl = await _uploadImage();
}

final updatedUser = UserModel(
id: widget.user.id,
name: _nameController.text.trim(),
phone: _phoneController.text.trim(),
email: _emailController.text.trim(),
profilePicture: imageUrl ?? widget.user.profilePicture,
balance: widget.user.balance,
contacts: widget.user.contacts,
);

await FirebaseFirestore.instance
    .collection('users')
    .doc(widget.user.id)
    .update(updatedUser.toJson());

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Profil mis à jour avec succès'),
backgroundColor: Colors.green,
),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Erreur lors de la mise à jour du profil: $e'),
backgroundColor: Colors.red,
),
);
} finally {
setState(() => _isLoading = false);
}
}

Future<void> _changePassword() async {
if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Veuillez remplir les champs de mot de passe.'),
backgroundColor: Colors.red,
),
);
return;
}

try {
final user = FirebaseAuth.instance.currentUser;

final credential = EmailAuthProvider.credential(
email: widget.user.email,
password: _currentPasswordController.text.trim(),
);

await user!.reauthenticateWithCredential(credential);
await user.updatePassword(_newPasswordController.text.trim());

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Mot de passe mis à jour avec succès'),
backgroundColor: Colors.green,
),
);

_currentPasswordController.clear();
_newPasswordController.clear();
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Erreur lors du changement de mot de passe: $e'),
backgroundColor: Colors.red,
),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Mon Profil'),
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Form(
key: _formKey,
child: Column(
children: [
GestureDetector(
onTap: _pickImage,
child: Stack(
alignment: Alignment.bottomRight,
children: [
CircleAvatar(
radius: 60,
backgroundImage: _imageFile != null
? FileImage(_imageFile!)
    : (widget.user.profilePicture.isNotEmpty
? NetworkImage(widget.user.profilePicture)
    : null) as ImageProvider?,
child: _imageFile == null && widget.user.profilePicture.isEmpty
? const Icon(Icons.person, size: 60, color: Colors.white)
    : null,
),
Container(
padding: const EdgeInsets.all(8),
decoration: const BoxDecoration(
color: Colors.blue,
shape: BoxShape.circle,
),
child: const Icon(
Icons.camera_alt,
color: Colors.white,
size: 20,
),
),
],
),
),
const SizedBox(height: 24),
TextFormField(
controller: _nameController,
decoration: const InputDecoration(
labelText: 'Nom',
prefixIcon: Icon(Icons.person),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Entrez votre nom';
}
return null;
},
),
const SizedBox(height: 16),
TextFormField(
controller: _phoneController,
decoration: const InputDecoration(
labelText: 'Téléphone',
prefixIcon: Icon(Icons.phone),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Entrez votre numéro de téléphone';
}
return null;
},
),
const SizedBox(height: 16),
TextFormField(
controller: _emailController,
decoration: const InputDecoration(
labelText: 'Email',
prefixIcon: Icon(Icons.email),
),
validator: (value) {
if (value == null || value.isEmpty) {
return 'Entrez votre adresse email';
}
return null;
},
),
const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 16),
TextFormField(
controller: _currentPasswordController,
decoration: const InputDecoration(
labelText: 'Mot de passe actuel',
prefixIcon: Icon(Icons.lock),
),
obscureText: true,
),
const SizedBox(height: 16),
TextFormField(
controller: _newPasswordController,
decoration: const InputDecoration(
labelText: 'Nouveau mot de passe',
prefixIcon: Icon(Icons.lock_outline),
),
obscureText: true,
),
const SizedBox(height: 24),
ElevatedButton(
onPressed: _isLoading ? null : _changePassword,
child: _isLoading
? const CircularProgressIndicator()
    : const Text('Changer le mot de passe'),
),
const SizedBox(height: 24),
ElevatedButton(
onPressed: _isLoading ? null : _updateProfile,
child: _isLoading
? const CircularProgressIndicator()
    : const Text('Mettre à jour le profil'),
),
],
),
),
),
);
}

@override
void dispose() {
_nameController.dispose();
_phoneController.dispose();
_emailController.dispose();
_currentPasswordController.dispose();
_newPasswordController.dispose();
super.dispose();
}
}

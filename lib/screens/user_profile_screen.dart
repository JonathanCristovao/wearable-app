import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/sensor_provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, _) {
          final users = provider.users;
          final selectedId = provider.selectedUser?.id;

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum usuário cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque em + para adicionar um usuário',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelected = user.id == selectedId;
              return _UserCard(
                user: user,
                isSelected: isSelected,
                onSelect: () => provider.selectUser(user.id),
                onEdit: () => _openUserForm(context, user: user),
                onDelete: () => _confirmDelete(context, provider, user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserForm(context),
        tooltip: 'Adicionar usuário',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _openUserForm(BuildContext context, {UserProfile? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserForm(user: user),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SensorProvider provider,
    UserProfile user,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text('Deseja excluir "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteUser(user.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.summary,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (user.disease != null && user.disease!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Doença: ${user.disease}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (user.injury != null && user.injury!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Lesão: ${user.injury}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (user.activityFrequency != null &&
                      user.activityFrequency!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Freq. atividade: ${user.activityFrequency}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check/select button
                IconButton(
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.check_circle_outline,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[400],
                  ),
                  tooltip: isSelected ? 'Desmarcar' : 'Selecionar',
                  onPressed: onSelect,
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 20,
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserForm extends StatefulWidget {
  final UserProfile? user;

  const _UserForm({this.user});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _injuryCtrl;
  late final TextEditingController _activityFreqCtrl;
  late final TextEditingController _diseaseCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _ageCtrl = TextEditingController(text: u?.age?.toString() ?? '');
    _weightCtrl = TextEditingController(
      text: u?.weight?.toStringAsFixed(1) ?? '',
    );
    _heightCtrl = TextEditingController(
      text: u?.height?.toStringAsFixed(0) ?? '',
    );
    _injuryCtrl = TextEditingController(text: u?.injury ?? '');
    _activityFreqCtrl = TextEditingController(
      text: u?.activityFrequency ?? '',
    );
    _diseaseCtrl = TextEditingController(text: u?.disease ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _injuryCtrl.dispose();
    _activityFreqCtrl.dispose();
    _diseaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<SensorProvider>();
    final isNew = widget.user == null;
    final id = widget.user?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final user = UserProfile(
      id: id,
      name: _nameCtrl.text.trim(),
      age: _ageCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_ageCtrl.text.trim()),
      weight: _weightCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_weightCtrl.text.trim()),
      height: _heightCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_heightCtrl.text.trim()),
      injury: _injuryCtrl.text.trim().isEmpty
          ? null
          : _injuryCtrl.text.trim(),
      activityFrequency: _activityFreqCtrl.text.trim().isEmpty
          ? null
          : _activityFreqCtrl.text.trim(),
      disease: _diseaseCtrl.text.trim().isEmpty
          ? null
          : _diseaseCtrl.text.trim(),
    );

    try {
      await provider.saveUser(user);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Usuário criado com sucesso!' : 'Usuário atualizado!',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.user == null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isNew ? 'Novo Usuário' : 'Editar Usuário',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Idade',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                        suffixText: 'anos',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0 || n > 130) {
                          return 'Idade inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Peso',
                        prefixIcon: Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(),
                        suffixText: 'kg',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0 || n > 500) {
                          return 'Peso inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightCtrl,
                decoration: const InputDecoration(
                  labelText: 'Altura',
                  prefixIcon: Icon(Icons.height),
                  border: OutlineInputBorder(),
                  suffixText: 'cm',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0 || n > 300) {
                    return 'Altura inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _activityFreqCtrl,
                decoration: const InputDecoration(
                  labelText: 'Frequência de atividade',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 3x por semana',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _injuryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lesão',
                  prefixIcon: Icon(Icons.healing),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Joelho direito',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diseaseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Doença',
                  prefixIcon: Icon(Icons.medical_information),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Hipertensão',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isNew ? 'Criar usuário' : 'Salvar alterações'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../cubit/user_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/models/user_model.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageUsers),
      ),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noUsersFound,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text("${user.email} • ${user.role == UserRole.subAdmin ? l10n.subAdmin : l10n.member}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Delete logic could be added here
                      },
                    ),
                  ),
                );
              },
            );
          }
          if (state is UserError) {
            return Center(child: Text(l10n.error(state.message)));
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/users/add'),
        label: Text(l10n.addUser),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.subAdmin;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _registerUser() {
    if (_formKey.currentState!.validate()) {
      final adminState = context.read<AuthCubit>().state;
      if (adminState is AuthAuthenticated) {
        context.read<UserCubit>().createSubUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          parentAdminUid: adminState.user.uid,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addNewUser),
      ),
      body: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state is UsersLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.userCreatedSuccess)),
            );
            context.pop();
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? l10n.invalidEmail : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.initialPassword,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? l10n.passwordMinLength : null,
                ),
                const SizedBox(height: 24),
                Text(l10n.userRole, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<UserRole>(
                  segments: [
                    ButtonSegment(value: UserRole.subAdmin, label: Text(l10n.subAdmin)),
                    ButtonSegment(value: UserRole.member, label: Text(l10n.member)),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (set) {
                    setState(() => _selectedRole = set.first);
                  },
                ),
                const SizedBox(height: 40),
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    final isLoading = state is UserLoading;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.registerUser),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

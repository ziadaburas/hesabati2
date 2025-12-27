import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/domain/entities/entities.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/account_form_screen.dart';
import '/presentation/screens/account_details_screen.dart';

/// شاشة قائمة الحسابات
class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  final LocalAccountController _accountController = Get.find<LocalAccountController>();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'all';
  String _selectedSort = 'date_desc';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _accountController.fetchLocalAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AccountEntity> get _filteredAccounts {
    var accounts = List<AccountEntity>.from(_accountController.localAccounts);

    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      accounts = accounts.where((a) {
        return a.accountName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (a.otherPartyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // تطبيق الفلتر
    if (_selectedFilter != 'all') {
      accounts = accounts.where((a) => a.accountType == _selectedFilter).toList();
    }

    // تطبيق الترتيب
    switch (_selectedSort) {
      case 'date_desc':
        accounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        accounts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'balance_desc':
        accounts.sort((a, b) => b.balance.compareTo(a.balance));
        break;
      case 'balance_asc':
        accounts.sort((a, b) => a.balance.compareTo(b.balance));
        break;
      case 'name':
        accounts.sort((a, b) => a.accountName.compareTo(b.accountName));
        break;
    }

    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الحسابات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          _buildSearchBar(),
          
          // الفلاتر السريعة
          _buildQuickFilters(),
          
          // قائمة الحسابات
          Expanded(
            child: Obx(() {
              if (_accountController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final accounts = _filteredAccounts;

              if (accounts.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => _accountController.fetchLocalAccounts(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    return _buildAccountCard(accounts[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'بحث عن حساب...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('all', 'الكل'),
          const SizedBox(width: 8),
          _buildFilterChip(AppConstants.accountTypeLoan, 'دين', AppColors.loan),
          const SizedBox(width: 8),
          _buildFilterChip(AppConstants.accountTypeDebt, 'مديونية', AppColors.debt),
          const SizedBox(width: 8),
          _buildFilterChip(AppConstants.accountTypeSavings, 'توفير', AppColors.savings),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, [Color? color]) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : 'all');
      },
      selectedColor: color?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.2),
      checkmarkColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppColors.primary) : Colors.grey[600],
      ),
    );
  }

  Widget _buildAccountCard(AccountEntity account) {
    final Color typeColor = _getAccountTypeColor(account.accountType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openAccountDetails(account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة نوع الحساب
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAccountTypeIcon(account.accountType),
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 16),
              
              // معلومات الحساب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            account.accountTypeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: typeColor,
                            ),
                          ),
                        ),
                        if (account.otherPartyName != null && account.otherPartyName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              account.otherPartyName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // الرصيد
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${account.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: account.balance >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    AppConstants.currencySymbol,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد حسابات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب كلمات بحث أخرى'
                : 'ابدأ بإضافة حسابك الأول',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return AppColors.loan;
      case AppConstants.accountTypeDebt:
        return AppColors.debt;
      case AppConstants.accountTypeSavings:
        return AppColors.savings;
      case AppConstants.accountTypeShared:
        return AppColors.shared;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case AppConstants.accountTypeLoan:
        return Icons.arrow_circle_down;
      case AppConstants.accountTypeDebt:
        return Icons.arrow_circle_up;
      case AppConstants.accountTypeSavings:
        return Icons.savings;
      case AppConstants.accountTypeShared:
        return Icons.people;
      default:
        return Icons.account_balance;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ترتيب الحسابات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('date_desc', 'الأحدث أولاً', setModalState),
                      _buildSortChip('date_asc', 'الأقدم أولاً', setModalState),
                      _buildSortChip('balance_desc', 'الأعلى رصيداً', setModalState),
                      _buildSortChip('balance_asc', 'الأقل رصيداً', setModalState),
                      _buildSortChip('name', 'الاسم', setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String value, String label, StateSetter setModalState) {
    final isSelected = _selectedSort == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {});
        setState(() => _selectedSort = value);
      },
    );
  }

  void _addAccount() async {
    final result = await Get.to(() => const AccountFormScreen());
    if (result == true) {
      await _accountController.fetchLocalAccounts();
    }
  }

  void _openAccountDetails(AccountEntity account) async {
    final result = await Get.to(() => AccountDetailsScreen(accountId: account.accountId));
    if (result == true) {
      await _accountController.fetchLocalAccounts();
    }
  }
}

import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/providers/userdata_provider.dart';
import 'package:finmate/screens/home/Group%20screens/group_chats.dart';
import 'package:finmate/screens/home/Group%20screens/group_members.dart';
import 'package:finmate/screens/home/Group%20screens/group_settings.dart';
import 'package:finmate/screens/home/Transaction%20screens/all_transactions_screen.dart';
import 'package:finmate/services/navigation_services.dart';
import 'package:finmate/widgets/fullscreen_image_viewer.dart'; // Add this import
import 'package:finmate/widgets/other_widgets.dart';
import 'package:finmate/widgets/transaction_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class GroupOverview extends ConsumerStatefulWidget {
  const GroupOverview({super.key, required this.group});
  final Group group;

  @override
  ConsumerState<GroupOverview> createState() => _GroupOverviewState();
}

class _GroupOverviewState extends ConsumerState<GroupOverview> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final List<String> tabTitles = ["Overview", "Chats", "Members"];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color4,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final UserData userData = ref.watch(userDataNotifierProvider);
    return AppBar(
      backgroundColor: color4,
      centerTitle: true,
      title: Text(
        widget.group.name ?? "Group Overview",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color1,
          fontSize: 20,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomTabBar(
          selectedIndex: _selectedIndex,
          tabTitles: tabTitles,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
        ),
      ),
      actions: [
        Visibility(
          visible: widget.group.creatorId == userData.uid,
          child: IconButton(
            onPressed: () =>
                Navigate().push(GroupSettings(group: widget.group)),
            icon: Icon(Icons.settings, color: color3),
            tooltip: 'Group Settings',
          ),
        ),
        sbw10,
      ],
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        GrpOverview(group: widget.group),
        GroupChats(group: widget.group),
        GroupMembers(group: widget.group),
      ],
    );
  }
}

// __________________________________________________________________________ //

class GrpOverview extends ConsumerWidget {
  const GrpOverview({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserData userData = ref.watch(userDataNotifierProvider);
    final List<UserData>? groupMembersData = group.listOfMembers;

    return Scaffold(
      backgroundColor: color4,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(context, userData, groupMembersData),
            const SizedBox(height: 24),
            _buildTransactionsSection(context, ref),
          ],
        ),
      ),
    );
  }

  /// Builds the card showing group balance and member contributions
  Widget _buildBalanceCard(BuildContext context, UserData userData,
      List<UserData>? groupMembersData) {
    final double totalAmount =
        double.tryParse(group.totalAmount ?? "0.0") ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color2.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: color4,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${group.totalAmount} ₹',
                  style: TextStyle(
                    color: color4,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Member Balances
            if (groupMembersData != null && groupMembersData.isNotEmpty)
              ...groupMembersData.map((member) =>
                  _buildMemberBalanceRow(context, member, totalAmount)),
          ],
        ),
      ),
    );
  }

  /// Builds a row showing a member's balance with a progress indicator
  Widget _buildMemberBalanceRow(
      BuildContext context, UserData member, double totalAmount) {
    // Get member balance and calculate percentage
    final double memberBalance =
        double.tryParse(group.membersBalance?[member.uid] ?? "0.0") ?? 0.0;

    // Calculate percentage (with safety checks)
    final double percentage = (totalAmount > 0 && memberBalance > 0)
        ? (memberBalance / totalAmount).clamp(0.0, 1.0)
        : 0.0;

    final bool isNegative = memberBalance < 0;
    final Color progressColor = isNegative ? Colors.red.shade400 : color4;
    final Color textColor = isNegative ? Colors.red.shade300 : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Member Avatar - Make it tappable to view profile picture in fullscreen
          GestureDetector(
            onTap: () {
              if (member.pfpURL != null && member.pfpURL!.isNotEmpty) {
                Navigate().push(
                  FullScreenImageViewer(
                    imageUrl: member.pfpURL!,
                    heroTag: 'profile_${member.uid}',
                  ),
                );
              }
            },
            child: Hero(
              tag: 'profile_${member.uid}',
              child: userProfilePicInCircle(
                imageUrl: member.pfpURL ?? '',
                outerRadius: 22,
                innerRadius: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Progress Bar and Balance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Name
                Text(
                  member.name ?? 'Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Linear Progress Indicator
                LinearPercentIndicator(
                  lineHeight: 12.0,
                  percent: percentage,
                  backgroundColor: Colors.white24,
                  progressColor: progressColor,
                  barRadius: const Radius.circular(6),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 800,
                ),

                const SizedBox(height: 4),

                // Balance Amount
                Text(
                  '$memberBalance ₹',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the recent transactions section
  Widget _buildTransactionsSection(BuildContext context, WidgetRef ref) {
    // Get and sort transactions
    List<Transaction>? transactions = group.listOfTransactions ?? [];

    // Sort by date and time (newest first)
    transactions.sort((a, b) {
      int dateComparison = b.date!.compareTo(a.date!);
      if (dateComparison != 0) return dateComparison;
      return b.time!.format(context).compareTo(a.time!.format(context));
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: color3,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (transactions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigate().push(AllTransactionsScreen(
                          transactionsList: transactions));
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: color3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // const SizedBox(height: 8),
          transactions.isEmpty
              ? _buildEmptyTransactions()
              : _buildTransactionsList(context, transactions, ref),
        ],
      ),
    );
  }

  /// Builds an empty state for when there are no transactions
  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No Transactions Yet",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Group transactions will appear here",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of recent transactions
  Widget _buildTransactionsList(
      BuildContext context, List<Transaction> transactions, WidgetRef ref) {
    // Take at most 4 recent transactions
    final recentTransactions = transactions.take(4).toList();

    return Column(
      children: recentTransactions
          .map((transaction) => transactionTile(context, transaction, ref))
          .toList(),
    );
  }
}

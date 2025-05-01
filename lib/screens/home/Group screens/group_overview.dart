import 'package:cached_network_image/cached_network_image.dart';
import 'package:finmate/constants/colors.dart';
import 'package:finmate/constants/const_widgets.dart';
import 'package:finmate/models/group.dart';
import 'package:finmate/models/transaction.dart';
import 'package:finmate/models/user.dart';
import 'package:finmate/models/user_finance_data.dart';
import 'package:finmate/providers/user_financedata_provider.dart';
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
    final UserFinanceData userFinanceData =
        ref.watch(userFinanceDataNotifierProvider);
    final group = userFinanceData.listOfGroups
            ?.firstWhere((g) => g.gid == widget.group.gid) ??
        widget.group;
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        screensWithRefreshButton(ref, GrpOverview(group: group)),
        screensWithRefreshButton(ref, GroupChats(group: group)),
        screensWithRefreshButton(ref, GroupMembers(group: group)),
      ],
    );
  }
}

Widget screensWithRefreshButton(
  WidgetRef ref,
  Widget child,
) {
  final String? uid = ref.watch(userDataNotifierProvider).uid;
  return RefreshIndicator.adaptive(
    onRefresh: () async {
      await ref
          .read(userFinanceDataNotifierProvider.notifier)
          .refetchAllGroupData(uid ?? "");
    },
    child: child,
  );
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
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupDetailsCard(context, userData),
            const SizedBox(height: 16),
            _buildBalanceCard(context, userData, groupMembersData),
            const SizedBox(height: 24),
            _buildTransactionsSection(context, ref),
          ],
        ),
      ),
    );
  }

  /// Builds the unified group details card with profile picture and description
  Widget _buildGroupDetailsCard(BuildContext context, UserData userData) {
    final bool isCreator = userData.uid == group.creatorId;
    final bool hasImage = group.image != null && group.image!.isNotEmpty;
    final bool hasDescription =
        group.description != null && group.description!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Profile Picture
                GestureDetector(
                  onTap: hasImage
                      ? () => Navigate().push(
                            FullScreenImageViewer(
                              imageUrl: group.image!,
                              heroTag: 'group_image_${group.gid}',
                            ),
                          )
                      : null,
                  child: Hero(
                    tag: 'group_image_${group.gid}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color2.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color3.withAlpha(100),
                          width: 2,
                        ),
                        image: hasImage
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(group.image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !hasImage
                          ? Center(
                              child: Icon(
                                Icons.groups_rounded,
                                size: 40,
                                color: color2,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name and Admin Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              group.name ?? "Group",
                              style: TextStyle(
                                color: color2,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCreator)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color3.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Admin",
                                style: TextStyle(
                                  color: color3,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Creation Date
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        group.date != null
                            ? "Created on ${group.date!.day}/${group.date!.month}/${group.date!.year}"
                            : "Created Today",
                      ),

                      const SizedBox(height: 4),

                      // Member Count
                      _buildInfoRow(
                        Icons.people_outline_rounded,
                        "${group.listOfMembers?.length ?? 0} Members",
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description section (only shown if there is a description)
            if (hasDescription) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.info_outline_rounded,
                "About this group",
                isTitle: true,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  group.description ?? "",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper method to build info rows with icons
  Widget _buildInfoRow(IconData icon, String text, {bool isTitle = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: isTitle ? 18 : 16,
          color: isTitle ? color3 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isTitle ? color2 : Colors.grey.shade600,
              fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
              fontSize: isTitle ? 15 : 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final double memberBalance = double.tryParse(
            group.membersBalance?[member.uid]?['currentAmount'] ?? "0.0") ??
        0.0;

    // Get initial amount (for potential display or calculations)
    final double initialAmount = double.tryParse(
            group.membersBalance?[member.uid]?['initialAmount'] ?? "0.0") ??
        0.0;

    // Calculate percentage (with safety checks)
    final double percentage = (initialAmount > 0 && memberBalance > 0)
        ? (memberBalance / initialAmount).clamp(0.0, 1.0)
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
                Row(
                  children: [
                    Text(
                      '$memberBalance ₹',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Only show initial amount if different from current
                    if (initialAmount != memberBalance)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '(initial: $initialAmount ₹)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
                if (transactions.isNotEmpty)
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

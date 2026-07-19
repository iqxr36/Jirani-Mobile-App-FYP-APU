// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : resident_reviews_view_state.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_reviews_view.dart';

class _ResidentReviewsViewState extends State<ResidentReviewsView> {
  _ReviewTab _selectedTab = _ReviewTab.all;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottom),
                      child: user == null
                          ? const _SignedOutState()
                          : _ReviewsContent(
                              user: user,
                              selectedTab: _selectedTab,
                              onTabChanged: (tab) =>
                                  setState(() => _selectedTab = tab),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

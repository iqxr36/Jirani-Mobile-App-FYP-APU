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

part of '../public_resident_profile_view.dart';

class PublicResidentProfileView extends StatelessWidget {
  const PublicResidentProfileView({
    super.key,
    required this.userId,
    this.fallbackName = 'Resident',
  });

  final String userId;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final profileRepository = PublicProfileRepository();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<PublicResidentProfile?>(
            stream: profileRepository.watchProfile(userId),
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            18,
                            16,
                            24 + bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(onBack: () => Navigator.of(context).pop()),
                              const SizedBox(height: 16),
                              if (userSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  user == null)
                                const _StatePanel(
                                  icon: Icons.person_search_rounded,
                                  title: 'Loading profile',
                                  message:
                                      'Checking resident reputation and listings.',
                                )
                              else if (userSnapshot.hasError)
                                _StatePanel(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Profile unavailable',
                                  message: userSnapshot.error
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                )
                              else if (user == null)
                                _StatePanel(
                                  icon: Icons.person_off_outlined,
                                  title: 'Resident not found',
                                  message:
                                      '$fallbackName may no longer have an active profile.',
                                )
                              else
                                _PublicProfileContent(user: user),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

part of '../resident_connections_view.dart';

class ResidentConnectionsView extends StatefulWidget {
  const ResidentConnectionsView({super.key, this.communityName});

  final String? communityName;

  @override
  State<ResidentConnectionsView> createState() =>
      _ResidentConnectionsViewState();
}

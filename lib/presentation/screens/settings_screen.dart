import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/local_database.dart';
import '../../data/models/data_source_metadata.dart';
import '../../data/services/data_sync_service.dart';
import '../../l10n/app_localizations.dart';
import '../viewmodels/app_settings_view_model.dart';
import '../widgets/app_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _dataVersion = '0.0.0';
  String? _lastDataUpdate;
  List<DataSourceMetadata> _dataSources = const [];
  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadDataSources();
    _loadSyncMetadata();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<AppSettingsViewModel>();

    return AppShell(
      title: l10n.settings,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 12,
        itemBuilder: (context, index) {
          return switch (index) {
            0 => _SectionTitle(title: l10n.language),
            1 => Semantics(
              label: l10n.language,
              child: SegmentedButton<Locale>(
                segments: [
                  ButtonSegment(
                    value: const Locale('en'),
                    label: Text(l10n.english),
                  ),
                  ButtonSegment(
                    value: const Locale('my'),
                    label: Text(l10n.myanmar),
                  ),
                ],
                selected: {settings.locale},
                onSelectionChanged: (selection) {
                  settings.setLocale(selection.first);
                },
              ),
            ),
            2 => const SizedBox(height: AppSpacing.lg),
            3 => _SectionTitle(title: l10n.theme),
            4 => Semantics(
              label: l10n.theme,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.light),
                  ),
                  ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.system),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) {
                  settings.setThemeMode(selection.first);
                },
              ),
            ),
            5 => ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: Text(l10n.clearCache),
              subtitle: Text(l10n.clearCacheDescription),
              minLeadingWidth: 48,
              onTap: _clearCache,
            ),
            6 => const Divider(),
            7 => _SectionTitle(title: 'Route data'),
            8 => _DataSourceTile(
              metadata: _dataSources.firstOrNull,
              dataVersion: _dataVersion,
              lastDataUpdate: _lastDataUpdate,
            ),
            9 => ListTile(
              leading: _isCheckingUpdates
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              title: const Text('Check for updates'),
              subtitle: const Text(
                'Download newer YBS route data if available.',
              ),
              minLeadingWidth: 48,
              enabled: !_isCheckingUpdates,
              onTap: _isCheckingUpdates ? null : _checkForUpdates,
            ),
            10 => const Divider(),
            _ => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(AppConstants.appNameEn),
              subtitle: Text(_version.isEmpty ? l10n.versionLoading : _version),
              minLeadingWidth: 48,
            ),
          };
        },
      ),
    );
  }

  Future<void> _loadSyncMetadata() async {
    final syncService = context.read<DataSyncService>();
    final dataVersion = await syncService.getLocalDataVersion();
    final lastDataUpdate = await syncService.getLastUpdated();
    if (!mounted) {
      return;
    }
    setState(() {
      _dataVersion = dataVersion;
      _lastDataUpdate = lastDataUpdate;
    });
  }

  Future<void> _loadDataSources() async {
    final database = context.read<LocalDatabase>();
    final dataSources = await database.getDataSources();
    if (!mounted) {
      return;
    }
    setState(() {
      _dataSources = dataSources;
    });
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_route_searches');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdates = true;
    });
    final result = await context.read<DataSyncService>().checkAndSync();
    await _loadSyncMetadata();
    await _loadDataSources();
    if (!mounted) {
      return;
    }
    setState(() {
      _isCheckingUpdates = false;
    });
    final message = result.success
        ? result.updated
              ? 'Route data updated to v${result.version}'
              : 'Route data is already up to date.'
        : 'Could not check updates.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DataSourceTile extends StatelessWidget {
  const _DataSourceTile({
    required this.metadata,
    required this.dataVersion,
    required this.lastDataUpdate,
  });

  final DataSourceMetadata? metadata;
  final String dataVersion;
  final String? lastDataUpdate;

  @override
  Widget build(BuildContext context) {
    final value = metadata;
    if (value == null) {
      return const ListTile(
        leading: Icon(Icons.dataset_outlined),
        title: Text('No route data metadata'),
        subtitle: Text('Seed data has not recorded source metadata yet.'),
        minLeadingWidth: 48,
      );
    }

    final updated = MaterialLocalizations.of(
      context,
    ).formatShortDate(value.lastUpdated);

    return ListTile(
      leading: const Icon(Icons.dataset_outlined),
      title: Text(value.name),
      subtitle: Text(
        'Data version: v$dataVersion\nLast updated: ${lastDataUpdate ?? updated}\nSource: ${value.version}\nConfidence: ${(value.confidence * 100).round()}%',
      ),
      isThreeLine: true,
      minLeadingWidth: 48,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

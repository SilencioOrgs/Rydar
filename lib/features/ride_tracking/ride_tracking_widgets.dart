part of 'ride_tracking_screen.dart';

class _RideControls extends StatelessWidget {
  const _RideControls({
    required this.isIdle,
    required this.isArmed,
    required this.isTracking,
    required this.isPaused,
    required this.isFinishing,
    required this.isLocating,
    required this.selectedVehicle,
    required this.onShowStartOptions,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
    required this.onFocusLocation,
  });
  final bool isIdle, isArmed, isTracking, isPaused, isFinishing;
  final bool isLocating;
  final RouteVehicle selectedVehicle;
  final VoidCallback onShowStartOptions;
  final VoidCallback onPause, onResume, onFinish;
  final VoidCallback onFocusLocation;

  @override
  Widget build(BuildContext context) {
    if (isFinishing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActionBubble(
          tooltip: 'Finish',
          icon: Icons.stop_rounded,
          onTap: isIdle ? null : onFinish,
        ),
        _PrimaryAction(
          icon: isIdle
              ? Icons.play_arrow_rounded
              : isArmed
              ? Icons.radar_rounded
              : isTracking
              ? Icons.pause_rounded
              : isPaused
              ? Icons.play_arrow_rounded
              : _vehicleIcon(selectedVehicle),
          onTap: isArmed
              ? onFocusLocation
              : isTracking
              ? onPause
              : isPaused
              ? onResume
              : onShowStartOptions,
        ),
        _ActionBubble(
          tooltip: 'Focus location',
          icon: isLocating
              ? Icons.gps_fixed_rounded
              : Icons.my_location_rounded,
          onTap: onFocusLocation,
        ),
      ],
    );
  }
}

class _StartOptionsSheet extends StatelessWidget {
  const _StartOptionsSheet({
    required this.selectedVehicle,
    required this.recordForLeaderboard,
    required this.selectedMotorModel,
    required this.selectedMotorModelId,
    required this.onRecordForLeaderboardChanged,
    required this.onMotorModelChanged,
    required this.onStartExitBubble,
    required this.onStartImmediate,
    required this.onStartOfflineExitBubble,
    required this.onStartOfflineImmediate,
  });

  final RouteVehicle selectedVehicle;
  final bool recordForLeaderboard;
  final ScooterModel? selectedMotorModel;
  final String? selectedMotorModelId;
  final ValueChanged<bool> onRecordForLeaderboardChanged;
  final ValueChanged<ScooterModel> onMotorModelChanged;
  final VoidCallback onStartExitBubble;
  final VoidCallback onStartImmediate;
  final VoidCallback onStartOfflineExitBubble;
  final VoidCallback onStartOfflineImmediate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: AppColors.glassBlur,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xF0101010),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder(0.12)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _vehicleIcon(selectedVehicle),
                          color: AppColors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Start ${selectedVehicle.label.toLowerCase()} ride',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.text.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LeaderboardRecordOption(
                    enabled: recordForLeaderboard,
                    selectedMotorModel: selectedMotorModel,
                    selectedMotorModelId: selectedMotorModelId,
                    onChanged: onRecordForLeaderboardChanged,
                    onMotorModelChanged: onMotorModelChanged,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 380;
                      final exitBubbleButton = _StartModeButton(
                        label: 'Exit bubble',
                        caption: 'Timer starts after you leave',
                        icon: Icons.radar_rounded,
                        filled: true,
                        onTap: onStartExitBubble,
                      );
                      final immediateButton = _StartModeButton(
                        label: 'Start now',
                        caption: 'Record immediately',
                        icon: Icons.bolt_rounded,
                        filled: false,
                        onTap: onStartImmediate,
                      );
                      if (isNarrow) {
                        return Column(
                          children: [
                            exitBubbleButton,
                            const SizedBox(height: 8),
                            immediateButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: exitBubbleButton),
                          const SizedBox(width: 8),
                          Expanded(child: immediateButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _OfflineStartChip(
                          label: 'Offline bubble',
                          onTap: recordForLeaderboard
                              ? null
                              : onStartOfflineExitBubble,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OfflineStartChip(
                          label: 'Offline now',
                          onTap: recordForLeaderboard
                              ? null
                              : onStartOfflineImmediate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartModeButton extends StatelessWidget {
  const _StartModeButton({
    required this.label,
    required this.caption,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: filled
              ? AppColors.orange
              : AppColors.glassWhite(0.08),
          foregroundColor: filled ? Colors.white : AppColors.text,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled ? AppColors.orange : AppColors.glassBorder(0.14),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (filled ? Colors.white : AppColors.text)
                          .withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineStartChip extends StatelessWidget {
  const _OfflineStartChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.offline_bolt_rounded, size: 16),
        label: FittedBox(child: Text(label.toUpperCase())),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: BorderSide(color: AppColors.orange.withValues(alpha: 0.48)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _LeaderboardRecordOption extends StatelessWidget {
  const _LeaderboardRecordOption({
    required this.enabled,
    required this.selectedMotorModel,
    required this.selectedMotorModelId,
    required this.onChanged,
    required this.onMotorModelChanged,
  });

  final bool enabled;
  final ScooterModel? selectedMotorModel;
  final String? selectedMotorModelId;
  final ValueChanged<bool> onChanged;
  final ValueChanged<ScooterModel> onMotorModelChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder(0.12)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: onChanged,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.orange,
            activeTrackColor: AppColors.orange.withValues(alpha: 0.28),
            secondary: const Icon(
              Icons.leaderboard_rounded,
              color: AppColors.orange,
            ),
            title: const Text(
              'Record in leaderboards',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              'Online only. Saves your weekly top speed by location and motor.',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.56),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            MotorcycleCategoryPicker(
              selected: selectedMotorModel,
              selectedId: selectedMotorModelId,
              onSelected: onMotorModelChanged,
              brandLabel: 'Motor brand',
              modelLabel: 'Motor model',
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stats bar
// ═══════════════════════════════════════════════════════════════════════════
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.controller});
  final RideTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: AppColors.glassBlur,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  'Distance',
                  DistanceUtils.formatMeters(controller.distanceMeters),
                ),
              ),
              _Divider(),
              Expanded(
                child: _Stat(
                  'Duration',
                  DurationUtils.formatSeconds(controller.durationSeconds),
                ),
              ),
              _Divider(),
              Expanded(
                child: _Stat(
                  'Speed',
                  '${SpeedUtils.formatKmh(controller.currentSpeedMetersPerSecond)} km/h',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.glassBorder(0.12));
}

// ═══════════════════════════════════════════════════════════════════════════
//  Route planner bar
// ═══════════════════════════════════════════════════════════════════════════
class _RoutePlannerBar extends StatelessWidget {
  const _RoutePlannerBar({required this.controller, required this.onOpen});
  final RideTrackingController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final route = controller.plannedRoute;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: GestureDetector(
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder(0.10)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_location_alt_rounded,
                  color: AppColors.orange,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.finishLine == null
                        ? 'Pin finish line on the map'
                        : route == null
                        ? 'Finish pinned - choose route options'
                        : controller.isOfflineMode
                        ? 'Offline guide: ${DistanceUtils.formatMeters(route.distanceMeters)}'
                        : 'Orange route: ${DistanceUtils.formatMeters(route.distanceMeters)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (controller.isPlanningRoute)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    controller.finishLine == null
                        ? Icons.search_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Route tools card (bottom sheet)
// ═══════════════════════════════════════════════════════════════════════════
class _RouteToolsCard extends StatefulWidget {
  const _RouteToolsCard({
    required this.controller,
    required this.onPinOnMap,
    this.scrollController,
  });
  final RideTrackingController controller;
  final VoidCallback onPinOnMap;
  final ScrollController? scrollController;

  @override
  State<_RouteToolsCard> createState() => _RouteToolsCardState();
}

class _RouteToolsCardState extends State<_RouteToolsCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    setState(() {});
  }

  Future<void> _searchPlaces() {
    FocusScope.of(context).unfocus();
    return widget.controller.searchPlaces(_searchController.text);
  }

  Future<void> _selectPlace(MapboxPlace place) async {
    final needsLocation = widget.controller.navigationOrigin == null;
    widget.controller.selectPlaceAsFinishLine(place);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
    if (needsLocation) {
      await widget.controller.focusOnCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final route = controller.plannedRoute;
    final canSearch =
        _searchController.text.trim().length >= 2 &&
        !controller.isSearchingPlaces;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: AppColors.glassBlur,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder(0.12)),
          ),
          child: ListView(
            controller: widget.scrollController,
            shrinkWrap: widget.scrollController == null,
            padding: EdgeInsets.zero,
            children: [
              _RouteToolsHeader(
                hasFinishLine: controller.finishLine != null,
                onClear: controller.finishLine == null
                    ? null
                    : controller.clearFinishLine,
              ),
              const SizedBox(height: 12),
              _RoutePanelSection(
                title: 'Search finish',
                icon: Icons.search_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DestinationSearch(
                      controller: _searchController,
                      isSearching: controller.isSearchingPlaces,
                      canSearch: canSearch,
                      onClear: () => _searchController.clear(),
                      onSearch: _searchPlaces,
                    ),
                    if (controller.placeSearchMessage != null) ...[
                      const SizedBox(height: 8),
                      _InlineStatusMessage(controller.placeSearchMessage!),
                    ],
                    if (controller.placeSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...controller.placeSuggestions.take(4).map((place) {
                        return _PlaceSuggestionTile(
                          place: place,
                          onTap: () => _selectPlace(place),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              _RoutePanelSection(
                title: 'Pin finish',
                icon: Icons.add_location_alt_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PinOnMapButton(
                      hasFinishLine: controller.finishLine != null,
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        widget.onPinOnMap();
                      },
                    ),
                    const SizedBox(height: 12),
                    _BubbleRadiusControl(controller: controller),
                  ],
                ),
              ),
              _RoutePanelSection(
                title: 'Vehicle',
                icon: _vehicleIcon(controller.selectedVehicle),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VehicleSelector(controller: controller),
                    if (controller.selectedVehicle ==
                        RouteVehicle.motorcycle) ...[
                      const SizedBox(height: 14),
                      _MotorModelSelector(controller: controller),
                    ],
                  ],
                ),
              ),
              if (route != null)
                _RouteDetailsRow(
                  route: route,
                  isOfflineMode: controller.isOfflineMode,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable primitives
// ═══════════════════════════════════════════════════════════════════════════
class _RouteToolsHeader extends StatelessWidget {
  const _RouteToolsHeader({required this.hasFinishLine, required this.onClear});

  final bool hasFinishLine;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.flag_rounded, color: AppColors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasFinishLine ? 'Finish line pinned' : 'Set finish line',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        if (onClear != null)
          IconButton(
            tooltip: 'Clear finish line',
            onPressed: onClear,
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.text.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
      ],
    );
  }
}

class _PinOnMapButton extends StatelessWidget {
  const _PinOnMapButton({required this.hasFinishLine, required this.onPressed});

  final bool hasFinishLine;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          hasFinishLine
              ? Icons.edit_location_alt_rounded
              : Icons.add_location_alt_rounded,
          size: 20,
        ),
        label: Text(hasFinishLine ? 'MOVE PIN ON MAP' : 'PIN ON MAP'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          side: BorderSide(color: AppColors.orange.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _RoutePanelSection extends StatelessWidget {
  const _RoutePanelSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.glassBorder(0.10)),
        ],
      ),
    );
  }
}

class _DestinationSearch extends StatelessWidget {
  const _DestinationSearch({
    required this.controller,
    required this.isSearching,
    required this.canSearch,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isSearching;
  final bool canSearch;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchField = TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          style: const TextStyle(color: AppColors.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search place or address',
            hintStyle: TextStyle(color: AppColors.text.withValues(alpha: 0.45)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.orange,
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.text.withValues(alpha: 0.48),
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.glassWhite(0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            border: _searchBorder(AppColors.glassBorder(0.12)),
            enabledBorder: _searchBorder(AppColors.glassBorder(0.12)),
            focusedBorder: _searchBorder(AppColors.orange),
          ),
        );
        final searchButton = SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: canSearch ? onSearch : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              disabledBackgroundColor: AppColors.glassWhite(0.08),
              disabledForegroundColor: AppColors.text.withValues(alpha: 0.34),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('SEARCH'),
          ),
        );

        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: searchButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            SizedBox(width: 98, child: searchButton),
          ],
        );
      },
    );
  }

  OutlineInputBorder _searchBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({required this.controller});

  final RideTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 330 ? 2 : 4;
        final gap = 8.0;
        final tileWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: RouteVehicle.values.map((vehicle) {
            final selected = vehicle == controller.selectedVehicle;
            return _VehicleButton(
              vehicle: vehicle,
              selected: selected,
              width: tileWidth,
              onTap: () => controller.selectVehicle(vehicle),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MotorModelSelector extends StatelessWidget {
  const _MotorModelSelector({required this.controller});

  final RideTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final selected =
        controller.selectedMotorModel ?? ScooterCatalog.defaultModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCOOTER CATEGORY',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.56),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        MotorcycleCategoryPicker(
          selected: selected,
          selectedId: controller.selectedMotorModelId,
          onSelected: controller.selectMotorModel,
          brandLabel: 'Motor brand',
          modelLabel: 'Motor model',
        ),
      ],
    );
  }
}

class _InlineStatusMessage extends StatelessWidget {
  const _InlineStatusMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: AppColors.text.withValues(alpha: 0.52),
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteDetailsRow extends StatelessWidget {
  const _RouteDetailsRow({required this.route, required this.isOfflineMode});

  final PlannedRoute route;
  final bool isOfflineMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: AppColors.orange, size: 16),
          const SizedBox(width: 6),
          Text(
            DistanceUtils.formatMeters(route.distanceMeters),
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 14),
          Icon(
            isOfflineMode ? Icons.offline_bolt_rounded : Icons.schedule_rounded,
            color: AppColors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isOfflineMode
                  ? 'Offline'
                  : DurationUtils.formatSeconds(route.durationSeconds),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleRadiusControl extends StatelessWidget {
  const _BubbleRadiusControl({required this.controller});

  final RideTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final radius = controller.geofenceRadiusMeters;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                color: AppColors.orange,
                size: 17,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Start / finish bubble',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${radius.round()} m',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            min: 10,
            max: 250,
            divisions: 24,
            value: radius.clamp(10, 250).toDouble(),
            activeColor: AppColors.orange,
            inactiveColor: AppColors.glassWhite(0.12),
            onChanged: controller.setGeofenceRadius,
          ),
          Text(
            'Leave the start bubble to begin. Enter the finish bubble to stop.',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.56),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  const _PlaceSuggestionTile({required this.place, required this.onTap});

  final MapboxPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder(0.10)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.74),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.orange, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.38),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_pin,
                  color: AppColors.orange,
                  size: 34,
                ),
              ),
              Container(width: 2, height: 22, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPickerActions extends StatelessWidget {
  const _PinPickerActions({required this.onCancel, required this.onPin});

  final VoidCallback onCancel;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: AppColors.glassBlur,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              _ActionBubble(
                tooltip: 'Cancel pin',
                icon: Icons.close_rounded,
                onTap: onCancel,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: onPin,
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('PIN FINISH LINE'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _VehicleButton extends StatelessWidget {
  const _VehicleButton({
    required this.vehicle,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final RouteVehicle vehicle;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.glassWhite(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.glassBorder(0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _vehicleIcon(vehicle),
                size: 22,
                color: selected ? Colors.white : AppColors.text,
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  vehicle.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _MapShade extends StatelessWidget {
  const _MapShade();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.75),
            ],
            stops: const [0, 0.25, 0.6, 1],
          ),
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.glassWhite(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder(0.14)),
              ),
              child: Icon(icon, color: AppColors.text, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  const _ActionBubble({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onTap == null
                        ? AppColors.glassBorder(0.10)
                        : AppColors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(icon, color: AppColors.orange, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.orangeGlow, AppColors.orangeDeep],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 38),
      ),
    );
  }
}

IconData _vehicleIcon(RouteVehicle v) => switch (v) {
  RouteVehicle.car => Icons.directions_car_rounded,
  RouteVehicle.motorcycle => Icons.two_wheeler_rounded,
  RouteVehicle.bicycle => Icons.directions_bike_rounded,
  RouteVehicle.walking => Icons.directions_walk_rounded,
};

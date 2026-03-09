import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

const _bucket = 'gs://gymbro-f4ff7.firebasestorage.app';

final _urlCache = <String, Future<String?>>{};

Future<String?> getStorageUrl(String path) {
  return _urlCache.putIfAbsent(path, () async {
    try {
      final ref = FirebaseStorage.instanceFor(bucket: _bucket).ref(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[Storage] $path → ${e.code}: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Storage] $path → $e');
      return null;
    }
  });
}

/// Widget ที่โหลดรูปจาก Firebase Storage
/// ถ้าไม่มีรูป หรือ error → แสดง [placeholder]
class StorageImage extends StatefulWidget {
  final String storagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget placeholder;
  final BorderRadius? borderRadius;
  final double cropTop;

  const StorageImage({
    super.key,
    required this.storagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    required this.placeholder,
    this.borderRadius,
    this.cropTop = 0,
  });

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  Future<String?>? _urlFuture;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    _lastPath = widget.storagePath;
    _urlFuture = getStorageUrl(widget.storagePath);
  }

  @override
  void didUpdateWidget(StorageImage old) {
    super.didUpdateWidget(old);
    if (widget.storagePath != _lastPath) {
      _lastPath = widget.storagePath;
      setState(() {
        _urlFuture = getStorageUrl(widget.storagePath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey[400]),
              ),
            ),
          );
        }

        final url = snapshot.data;
        if (url == null) return widget.placeholder;

        Widget img = CachedNetworkImage(
          imageUrl: url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          placeholder: (_, __) => SizedBox(
            width: widget.width,
            height: widget.height,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey[400]),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => widget.placeholder,
        );

        if (widget.cropTop > 0 && widget.height != null) {
          img = SizedBox(
            width: widget.width,
            height: widget.height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                maxHeight: widget.height! + widget.cropTop,
                child: SizedBox(
                  height: widget.height! + widget.cropTop,
                  child: img,
                ),
              ),
            ),
          );
        }

        if (widget.borderRadius != null) {
          img = ClipRRect(borderRadius: widget.borderRadius!, child: img);
        }
        return img;
      },
    );
  }
}

const _exerciseImageMap = {
  'assisted_chin_up': 'assisted_chin_up.png',
  'assisted_dip': 'assisted_dip.png',
  'assisted_pull_up': 'assisted_pull_up.png',
  'back_extension': 'back_extension.png',
  'flat_barbell_bench_press': 'barbell_bench_press.png',
  'barbell_rack_pull': 'barbell_rack_pull.png',
  'barbell_row': 'barbell_row.png',
  'barbell_curl': 'bicep_curl.png',
  'dumbbell_curl': 'bicep_curl.png',
  'cable_chest_fly': 'cable_chest_fly.png',
  'seated_calf_raise': 'calf_raise.png',
  'machine_chest_press': 'chest_press.png',
  'dumbbell_bench_press': 'dumbbell_bench_press.png',
  'dumbbell_fly': 'dumbbell_fly.png',
  'dumbbell_shoulder_press': 'dumbbell_shoulder_press.png',
  'face_pull': 'face_pull.png',
  'high_foot_leg_press': 'high_foot_leg_press.png',
  'high_row_to_face': 'high_row_to_face.png',
  'incline_chest_press': 'incline_chest_press.png',
  'dumbbell_lateral_raise': 'lateral_raise.png',
  'lat_pulldown': 'latpulldown.png',
  'leg_curl': 'leg_curl.png',
  'leg_extension': 'leg_extension.png',
  'machine_crunch': 'machine_crunch.png',
  'oblique_crunch': 'oblique_crunch.png',
  'overhead_cable_extension': 'overhead_cable_extension.png',
  'barbell_overhead_press': 'overhead_press.png',
  'pec_deck_fly': 'pec_deck_fly.png',
  'reverse_grip_pec_deck': 'reverse_grip_pec_deck.png',
  'reverse_pec_deck': 'reverse_pec_deck.png',
  'romanian_deadlift': 'romanian_deadlift.png',
  'seated_row': 'seated_row.png',
  'machine_shoulder_press': 'shoulder_pressmachinedumbbell.png',
  'smith_machine_calf_raise': 'smith_calf_raise.png',
  'smith_machine_incline_press': 'smith_incline_press.png',
  'straight_arm_pulldown': 'straight_arm_pulldown.png',
  'dumbbell_tricep_extension': 'tricep_extension.png',
  'cable_tricep_pushdown': 'triceps_pushdown_rope.png',
  // Additional exercises
  'barbell_squat': 'barbell_squat.png',
  'cable_bicep_curl': 'cable_bicep_curl.png',
  'cable_crossover': 'cable_cross_over.png',
  'cable_cross_over': 'cable_cross_over.png',
  'deadlift': 'dead_lift.png',
  'dead_lift': 'dead_lift.png',
  'barbell_deadlift': 'dead_lift.png',
  'dual_lat_pulldown': 'dual_lat_pull_down.png',
  'dual_lat_pull_down': 'dual_lat_pull_down.png',
  'dumbbell_row': 'dumb_bell_row.png',
  'dumb_bell_row': 'dumb_bell_row.png',
  'dumbbell_tricep_kickback': 'dumb_bell_tricep_kick_back.png',
  'dumbbell_tricep_kick_back': 'dumb_bell_tricep_kick_back.png',
  'tricep_kickback': 'dumb_bell_tricep_kick_back.png',
  'dumbbell_front_raise': 'dumbbell_front_raise.png',
  'front_raise': 'dumbbell_front_raise.png',
  'leg_press': 'leg_press.png',
  'barbell_leg_press': 'leg_press.png',
  'snatch': 'snatch.png',
  'barbell_snatch': 'snatch.png',
};

String exerciseImagePath(String exerciseId) {
  final filename = _exerciseImageMap[exerciseId] ?? '$exerciseId.png';
  return 'exercises/$filename';
}

const _machineImageMap = {
  'aerobic_fitness_area_gym': '1_aerobic_fitness_area_gym.png',
  'assisted_pull_up_machine': '2_assisted_pull_up_machine.png',
  'barbell_rack': '3_barbell_rack.png',
  'bench': '4_bench.png',
  'cable_chest_fly': '5_cable_chest_fly.png',
  'cable_crossover_machine': '6_cable_crossover_machine.png',
  'captain_chair_abs_station': '7_captain_chair_abs_station.png',
  'cardio_zone_gym': '8_cardio_zone_gym.png',
  'chest_press_machine': '9_chest_press_machine.png',
  'curve_treadmill': '10_curve_treadmill.png',
  'dual_lat_machine': '11_dual_lat_machine.png',
  'dumbbell_rack': '12_dumbbell_rack.png',
  'ez_curl_bar_rack': '13_ez_curl_bar_rack.png',
  'flat_barbell_bench_press_station': '14_flat_barbell_bench_press_station.png',
  'gym_locker': '15_gym_locker.png',
  'gym_reception_counter': '16_gym_reception_counter.png',
  'gym_vending_machine': '17_gym_vending_machine.png',
  'hip_abductor_machine': '18_hip_abductor_machine.png',
  'hip_adductor_machine': '19_hip_adductor_machine.png',
  'incline_barbell_bench_press_station': '20_incline_barbell_bench_press_station.png',
  'incline_chest_press_machine': '21_incline_chest_press_machine.png',
  'lat_pull': '22_lat_pull.png',
  'lat_pulldown_machine': '23_lat_pulldown_machine.png',
  'lateral_raise_machine': '24_lateral_raise_machine.png',
  'leg_curl_machine': '25_leg_curl_machine.png',
  'leg_extension_machine': '26_leg_extension_machine.png',
  'lying_leg_curl_machine': '27_lying_leg_curl_machine.png',
  'olympic_lifting_platform': '28_olympic_lifting_platform.png',
  'pec_deck_fly': '29_pec_deck_fly.png',
  'preacher_curl_machine': '30_preacher_curl_machine.png',
  'roman_chair': '31_roman_chair.png',
  'row_machine': '32_row_machine.png',
  'rowing_machine': '33_rowing_machine.png',
  'seated_cable_row': '34_seated_cable_row.png',
  'seated_calf_press_machine': '35_seated_calf_press_machine.png',
  'seated_crunch_machine': '36_seated_crunch_machine.png',
  'seated_leg_curl_machine': '37_seated_leg_curl_machine.png',
  'seated_leg_press_machine': '38_seated_leg_press_machine.png',
  'seated_row_machine': '39_seated_row_machine.png',
  'seated_shoulder_press': '40_Seated Shoulder Press.png',
  'seated_triceps_press': '41_seated_triceps_press.png',
  'shoulder_press_machine': '42_shoulder_press_machine.png',
  'smith_machine': '43_smith_machine.png',
  'squat_rack': '44_squat_rack.png',
  'standing_leg_curl_machine': '45_standing_leg_curl_machine.png',
  'tricep_extension_machine': '46_tricep_extension_machine.png',
};

String machineImagePath(String machineId) {
  final filename = _machineImageMap[machineId] ?? '$machineId.png';
  return 'machine/$filename';
}

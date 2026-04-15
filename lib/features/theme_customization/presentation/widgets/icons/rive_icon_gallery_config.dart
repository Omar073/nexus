import 'package:rive/rive.dart';

/// Som icon animation asset (gallery skips [Demo] artboard only for this file).
const kSomIconAnimationRivPath = 'assets/21494-40458-som-icon-animation.riv';
const kAnimatedIconSetRivPath = 'assets/6477-12649-animated-icon-set.riv';

/// Rive assets under [assets/] to show in the gallery (path + section title).
const kRiveGallerySources = <(String path, String sectionTitle)>[
  (
    'assets/1298-2487-animated-icon-set-1-color.riv',
    'Animated icon set (color)',
  ),
  (kAnimatedIconSetRivPath, 'Animated icon set'),
  (kSomIconAnimationRivPath, 'Some icon animation'),
];

/// Artboards to omit from the gallery for Som icon animation only.
const kSomIconAnimationSkippedArtboards = {'Demo'};

/// This pack includes non-icon preview/container artboards; hide them.
const kAnimatedIconSetSkippedArtboards = {
  'New Artboard',
  'Icon-set',
  'Hover and Click',
};

const kSomPulseTriggerNames = ['Click', 'click', 'Activate'];
const kAnimatedIconSetPulseTriggerNames = ['Click', 'click', 'Tap', 'tap'];

/// Second [TriggerInput.fire] after the first, so the state machine can exit
/// the "played" state (same as a second tap).
const kSecondTriggerDelay = Duration(milliseconds: 1800);

/// Height reserved for the gallery body while Rive loads. Matches
/// [_buildGallery] (three labeled 120px strips + gaps) so the parent [ListView]
/// does not underestimate [maxScrollExtent] mid-fling.
const kRiveGalleryBodyReservedHeight = 500.0;

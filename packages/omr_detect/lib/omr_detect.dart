/// On-device OMR detection pipeline (pure-Dart core).
///
/// Stage order after warp: [ThresholdEngine] (7) → [BubbleClassifier] (8) →
/// [FieldDecoder] (9) → [ConfidenceAggregator] (10), with [CurvatureGate]
/// (4) judging the warp's flatness from the timing track. The OpenCV-bound
/// stages (registration, warp, ROI measurement) live behind `OpencvService`
/// and feed these pure stages with [BubbleSample]s and centroids — so the
/// marking decisions are testable on the host without a single pixel.
library;

export 'src/capture/hysteresis.dart'
    show HysteresisState, QuadHysteresis;
export 'src/capture/live_analyzer.dart'
    show LiveFrame, LiveFrameAnalyzer, ScannerTick;
export 'src/capture/quality_gates.dart'
    show CaptureQualityGates, GateInput, GateResult, GateType;
export 'src/cv/opencv_dart_impl.dart' show OpencvDartImpl;
export 'src/cv/opencv_service.dart'
    show
        CvExclude,
        CvMat,
        CvMatch,
        CvPointI,
        CvRectI,
        CvSizeI,
        DecodedStill,
        OpencvService;
export 'src/cv/smoke_probe.dart'
    show SmokeCheck, SmokeReport, runCvSmokeProbe;
export 'src/decode/field_decoder.dart' show FieldDecoder;
export 'src/models/bubble_read.dart'
    show BubbleRead, BubbleSample, BubbleZone, FieldRead, MarkClass;
export 'src/pipeline/bubble_classifier.dart' show BubbleClassifier;
export 'src/pipeline/bubble_reader.dart' show BubbleReader;
export 'src/pipeline/confidence_aggregator.dart'
    show ConfidenceAggregator, RegistrationQuality, SheetAssessment;
export 'src/pipeline/pipeline.dart'
    show
        OmrPipeline,
        RegistrationPath,
        RejectionReason,
        StageStatus,
        StageTraceEntry,
        StillEvaluation;
export 'src/registration/curvature_gate.dart'
    show CurvatureGate, CurvatureReport;
export 'src/registration/fiducial_registrar.dart'
    show
        FiducialMatch,
        FiducialRegistrar,
        FiducialSearch,
        RegistrationReport,
        fiducialSearchPlan;
export 'src/registration/homography_warper.dart' show HomographyWarper;
export 'src/thresholds/threshold_config.dart' show Strictness, ThresholdConfig;
export 'src/thresholds/threshold_engine.dart'
    show StripThreshold, ThresholdEngine, ThresholdResult;

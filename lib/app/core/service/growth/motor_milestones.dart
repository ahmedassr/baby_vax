/// The six gross motor milestones of the WHO Motor Development Study, with
/// their windows of achievement.
///
/// Source (pinned 22 November 2026, read in-session from who.int):
/// WHO Multicentre Growth Reference Study Group. WHO Motor Development
/// Study: Windows of achievement for six gross motor development
/// milestones. Acta Paediatrica 2006; Suppl 450: 86-95.
/// doi:10.1080/08035320500495563. Table II, "Estimated percentiles and
/// mean (SD) in days and months for the windows of milestone achievement":
/// each window is bound by the 1st and 99th percentiles, in months (days
/// divided by 30.4375). The paper: "The windows represent normal variation
/// in ages of milestone achievement among healthy children."
///
/// WHO's one-page table (mm_windows_table.pdf) gives 6.0 instead of 5.9 for
/// the start of walking with assistance; the paper's Table II is used.
///
/// The "what counts" texts in the app (`Milestone_<id>_criteria`) are plain
/// wording of the MGRS performance criteria, Table 1 of Wijnhoven TMA et
/// al., Assessment of gross motor development in the WHO Multicentre
/// Growth Reference Study, Food Nutr Bull 2004; 25(1 Suppl 1): S37-S45,
/// the paper the 2006 study cites for them. See docs/THIRD_PARTY.md.
enum MotorMilestone {
  sitting(3.8, 9.2),
  crawling(5.2, 13.5),
  standingAssisted(4.8, 11.4),
  walkingAssisted(5.9, 13.7),
  standingAlone(6.9, 16.9),
  walkingAlone(8.2, 17.6);

  const MotorMilestone(this.startMonths, this.endMonths);

  /// The 1st percentile, in months.
  final double startMonths;

  /// The 99th percentile, in months.
  final double endMonths;

  /// The Firestore document id, `users/{uid}/milestones/{id}`; must match
  /// the list in firestore.rules.
  String get id => name;

  /// Some healthy babies never crawl on hands and knees (4.3% in the
  /// study), so crawling is optional.
  bool get optional => this == MotorMilestone.crawling;

  static MotorMilestone? fromId(String? id) {
    for (final MotorMilestone m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// Where a milestone stands for a baby today.
enum MilestoneStatus {
  /// A date is recorded.
  achieved,

  /// Today is inside the window.
  dueNow,

  /// The window has not started.
  later,

  /// Crawling, not recorded: some babies skip it.
  optional,

  /// The window has ended and no date is recorded (never crawling).
  pastWindow;

  static MilestoneStatus of({
    required MotorMilestone milestone,
    required DateTime? achievedAt,
    required double? ageMonths,
  }) {
    if (achievedAt != null) return MilestoneStatus.achieved;
    if (milestone.optional) return MilestoneStatus.optional;
    if (ageMonths == null || ageMonths < milestone.startMonths) {
      return MilestoneStatus.later;
    }
    if (ageMonths <= milestone.endMonths) return MilestoneStatus.dueNow;
    return MilestoneStatus.pastWindow;
  }
}

class SymptomIntake {
  final int? symptomDurationWeeks; // how long symptoms have been present
  final bool familyHistoryFirstDegree; // mother/sister/daughter
  final bool geneticMutationKnown; // BRCA etc (if known)
  final bool priorBreastCancer;
  final bool currentlyPregnant;
  final bool breastfeeding;
  final bool onHormoneTherapy; // HRT / hormonal meds
  final bool smoker;
  final bool weightLossOrFatigue; // systemic symptoms (optional)

  const SymptomIntake({
    this.symptomDurationWeeks,
    this.familyHistoryFirstDegree = false,
    this.geneticMutationKnown = false,
    this.priorBreastCancer = false,
    this.currentlyPregnant = false,
    this.breastfeeding = false,
    this.onHormoneTherapy = false,
    this.smoker = false,
    this.weightLossOrFatigue = false,
  });

  Map<String, dynamic> toMap() => {
    "symptomDurationWeeks": symptomDurationWeeks,
    "familyHistoryFirstDegree": familyHistoryFirstDegree,
    "geneticMutationKnown": geneticMutationKnown,
    "priorBreastCancer": priorBreastCancer,
    "currentlyPregnant": currentlyPregnant,
    "breastfeeding": breastfeeding,
    "onHormoneTherapy": onHormoneTherapy,
    "smoker": smoker,
    "weightLossOrFatigue": weightLossOrFatigue,
  };
}

// ignore: avoid_classes_with_only_static_members
class DataUtil {
  static List<double> B_HR = [
    0.012493658738073,
    0,
    -0.024987317476146,
    0,
    0.012493658738073
  ];
  static List<double> A_HR = [
    1,
    -3.658469528008591,
    5.026987876570873,
    -3.078346646055655,
    0.709828779797188
  ];

  /// Takes in a [List<int>] of ecgDataPoints and filters/smoothes them to show a nicer visual representation
  /// returns a filtered [List<double>]
  static List<double> filterEcgData(List<int> dataList) {
    List<double> inPut = [0, 0, 0, 0, 0];
    List<double> outPut = [0, 0, 0, 0, 0];

    double filterEcgDataPoint(double data) {
      inPut[4] = data * 18.3 / 128 + 0.06;
      outPut[4] = B_HR[0] * inPut[4] +
          B_HR[1] * inPut[3] +
          B_HR[2] * inPut[2] +
          B_HR[3] * inPut[1] +
          B_HR[4] * inPut[0] -
          A_HR[1] * outPut[3] -
          A_HR[2] * outPut[2] -
          A_HR[3] * outPut[1] -
          A_HR[4] * outPut[0];
      for (int i = 0; i < 4; i++) {
        inPut[i] = inPut[i + 1];
        outPut[i] = outPut[i + 1];
      }
      return outPut[4];
    }

    return dataList.map((e) => filterEcgDataPoint(e.toDouble())).toList();
  }
}

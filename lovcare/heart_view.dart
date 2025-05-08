import 'dart:async';
import 'package:delayed_display/delayed_display.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:love_ring/core/constants/constants.dart';
import 'package:love_ring/core/manger/color_manger.dart';
import 'package:love_ring/core/manger/function_manger.dart';
import 'package:love_ring/core/manger/icon_manger.dart';
import 'package:love_ring/core/manger/image_manger.dart';
import 'package:love_ring/core/services/health_measurement_evaluator.dart';
import 'package:love_ring/core/services/health_repository.dart';
import 'package:love_ring/smartring/src/pages_data/ble_data.dart';
import 'package:love_ring/smartring/src/widget/hr_wave.dart';
import 'package:love_ring/view/home_view/notification_view.dart';
import 'package:love_ring/widgets/my_loading.dart';
import 'package:love_ring/widgets/my_text.dart';
import 'package:smartring_plugin/sdk/common/ble_protocol_constant.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import 'package:get/get.dart' as getx;

class HeartView extends StatefulWidget {
  const HeartView({super.key});

  @override
  State<HeartView> createState() => _HeartViewState();
}

class _HeartViewState extends State<HeartView> {
  String? selectedItem = easy.tr('lastDay');

  final List<String> items = [
    easy.tr('lastDay'),
    easy.tr('last30Days'),
    easy.tr('last90Days'),
  ];
  List<FlSpot> dataChart = [];

  final BleData _bleData = getx.Get.find<BleData>();
  final HealthRepository _healthRepository = getx.Get.find<HealthRepository>();
  final HealthMeasurementEvaluator _healthMeasurementEvaluator =
      getx.Get.find<HealthMeasurementEvaluator>();

  late Timer timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        try {
          _bleData.irWaveList.clear();
          MyLoading.show(context);
          dataChart = await _healthRepository.getLastDayHeartRate();
          _bleData.heartValue2.value =
              await _healthRepository.getLastHeartRateReading();

          if (_bleData.heartValue2.value.isNotEmpty) {
            _healthMeasurementEvaluator
                .evaluateHeartRate(int.parse(_bleData.heartValue2.value));
          }

          _bleData.sendBle(SendType.openSingleHealth);

          // Simulate live data every second
          timer = Timer.periodic(Duration(seconds: 1), (_) {
            setState(() {
              _updateSpots();
            });
          });

          setState(() {});
          MyLoading.dismiss();
        } on Exception catch (e) {
          MyLoading.dismiss();
        }
      },
    );
  }

  getx.RxList<FlSpot> spots = <FlSpot>[].obs;
  int counter = 0;
  void _updateSpots() {
    counter++;
    if (_bleData.irWaveList.isNotEmpty) {
      spots.value = _bleData.irWaveList
          .asMap()
          .entries
          .map((e) => FlSpot(counter * 1.0, e.value.toDouble() / 10))
          .toList();
      print("_updateSpots ${spots.last.x}  ${spots.last.y}  ${spots.last}");
    }
  }

  @override
  void dispose() {
    _bleData.sendBle(SendType.closeHealth);
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 1.sh,
        width: 1.sw,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(ImageManger.heartBackground),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              children: [
                //ABB BAR
                SizedBox(
                  height: 56,
                  width: 1.sw,
                  child: Row(
                    children: [
                      ZoomTapAnimation(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: SizedBox(
                          height: 56,
                          child: Align(
                            child: Image.asset(
                              IconManger.arrowLeft,
                              height: .035.sh,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: MyAutoText(
                          text: easy.tr("heartRate"),
                          textAlign: TextAlign.center,
                          color: ColorManger.white,
                          size: 16.sp,
                        ),
                      ),
                      ZoomTapAnimation(
                        onTap: () {
                          FunctionManager.myHapticFeedback();
                          FunctionManager.navigateWithAnimation(
                            context: context,
                            page: NotificationView(),
                          );
                        },
                        child: SizedBox(
                          height: 56,
                          child: Align(
                            child: Image.asset(
                              IconManger.notifacation,
                              height: .035.sh,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(6.h),
                DelayedDisplay(
                  delay: Duration(milliseconds: 300),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("heartRate"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                DelayedDisplay(
                  delay: Duration(milliseconds: 400),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("analyzingHeartRateToImproveHealth"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 8.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ],
                  ),
                ),
                Gap(10.h),
                SizedBox(
                  height: FunctionManager.getResponsiveSize(
                    context,
                    .34.sw * 2,
                    .27.sw * 2,
                  ),
                  width: 1.sw,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DelayedDisplay(
                          delay: Duration(milliseconds: 500),
                          slidingBeginOffset: const Offset(0.0, 0.3),
                          fadeIn: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              getx.Obx(
                                () => MyAutoText(
                                  text: _bleData.heartValue2.value.isNotEmpty
                                      ? _bleData.heartValue2.value
                                      : NA,
                                  color: ColorManger.white,
                                  size: FunctionManager.getResponsiveSize(
                                    context,
                                    33.sp,
                                    22.sp,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Gap(3),
                              Column(
                                children: [
                                  Spacer(flex: 2),
                                  MyAutoText(
                                    text: "BPM",
                                    color: ColorManger.grayHeart,
                                    size: FunctionManager.getResponsiveSize(
                                      context,
                                      16.sp,
                                      10.sp,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: DelayedDisplay(
                          delay: Duration(milliseconds: 600),
                          slidingBeginOffset: const Offset(0.0, 0.3),
                          fadeIn: true,
                          child: Stack(
                            children: [
                              LineChart(
                                LineChartData(
                                  // backgroundColor: ColorManger.tabBackground,
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: .4,
                                    verticalInterval: 9,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        // ignore: deprecated_member_use
                                        color:
                                            ColorManger.white.withOpacity(0.2),
                                        strokeWidth: .7,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        // ignore: deprecated_member_use
                                        color:
                                            ColorManger.white.withOpacity(0.2),
                                        strokeWidth: .7,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      //THIS IS POUNT TO DROW HEART CHART
                                      // spots: [
                                      //   FlSpot(0, 70),
                                      //   FlSpot(1, 60),
                                      //   FlSpot(2, 90),
                                      //   FlSpot(3, 110),
                                      //   FlSpot(4, 110),
                                      //   FlSpot(5, 110),
                                      //   FlSpot(6, 110),
                                      //   FlSpot(7, 110),
                                      // ],
                                      // spots: spots,
                                      spots: [],
                                      isCurved: true,
                                      color: ColorManger.redHeart,
                                      barWidth: 2.2,
                                      curveSmoothness: .56,

                                      dotData: FlDotData(
                                        show: true,
                                        checkToShowDot: (spot, barData) =>
                                            spot ==
                                            barData.spots
                                                .last, // إظهار الدائرة عند آخر نقطة
                                        getDotPainter: (
                                          spot,
                                          percent,
                                          barData,
                                          index,
                                        ) {
                                          return FlDotCirclePainter(
                                            radius:
                                                4.sp, // تحديد نصف القطر للنقطة
                                            color: ColorManger
                                                .redHeart, // تحديد لون النقطة
                                            strokeWidth: 4, // سمك حدود النقطة
                                            strokeColor: Color(
                                              0xffFFB1B6,
                                            ), // تحديد لون الحدود
                                          );
                                        },
                                      ),

                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                  minX: 0,
                                  maxY: 220,
                                  minY: 0,
                                ),
                              ),
                              getx.Obx(
                                () => HrWave(
                                    waveData: _bleData.irWaveList,
                                    update: _bleData.update.value,
                                    paintColor: 0xffda2048),
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DelayedDisplay(
                                        delay: Duration(milliseconds: 700),
                                        slidingBeginOffset: const Offset(
                                          0.0,
                                          0.3,
                                        ),
                                        fadeIn: true,
                                        child: LayoutBuilder(
                                          builder: (context, constrainedBox) {
                                            return Row(
                                              children: [
                                                Container(
                                                  width: 3.w,
                                                  height:
                                                      constrainedBox.maxHeight,
                                                  color: ColorManger.redHeart,
                                                ),
                                                Gap(6.w),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text: easy.tr(
                                                                    "current"),
                                                                color: ColorManger
                                                                    .grayHeart,
                                                                size: 18.sp,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text:
                                                                    "2.5 sec/sqt",
                                                                color:
                                                                    ColorManger
                                                                        .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Gap(6.w),
                                    Expanded(
                                      child: DelayedDisplay(
                                        delay: Duration(milliseconds: 800),
                                        slidingBeginOffset: const Offset(
                                          0.0,
                                          0.3,
                                        ),
                                        fadeIn: true,
                                        child: LayoutBuilder(
                                          builder: (context, constrainedBox) {
                                            return Row(
                                              children: [
                                                Container(
                                                  width: 3.w,
                                                  height:
                                                      constrainedBox.maxHeight,
                                                  color: ColorManger.redHeart,
                                                ),
                                                Gap(6.w),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text: easy.tr(
                                                                    "average"),
                                                                color: ColorManger
                                                                    .grayHeart,
                                                                size: 18.sp,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text:
                                                                    "1.9 sec/sqt",
                                                                color:
                                                                    ColorManger
                                                                        .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Gap(6.w),
                                    Expanded(
                                      child: DelayedDisplay(
                                        delay: Duration(milliseconds: 900),
                                        slidingBeginOffset: const Offset(
                                          0.0,
                                          0.3,
                                        ),
                                        fadeIn: true,
                                        child: LayoutBuilder(
                                          builder: (context, constrainedBox) {
                                            return Row(
                                              children: [
                                                Container(
                                                  width: 3.w,
                                                  height:
                                                      constrainedBox.maxHeight,
                                                  color: ColorManger.redHeart,
                                                ),
                                                Gap(6.w),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text: easy
                                                                    .tr("max"),
                                                                color: ColorManger
                                                                    .grayHeart,
                                                                size: 18.sp,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: MyAutoText(
                                                                text:
                                                                    "1.5 sec/sqt",
                                                                color:
                                                                    ColorManger
                                                                        .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DelayedDisplay(
                              delay: Duration(milliseconds: 1000),
                              slidingBeginOffset: const Offset(0.0, 0.3),
                              fadeIn: true,
                              child: MyAutoText(
                                text: easy.tr('lowHeartRate'),
                                color: ColorManger.white,
                                size: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DelayedDisplay(
                  delay: Duration(milliseconds: 1100),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("Recommendations"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
                DelayedDisplay(
                  delay: Duration(milliseconds: 1200),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("aimToReduceHeartRate"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 8.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ],
                  ),
                ),
                Gap(7.h),
                DelayedDisplay(
                  delay: Duration(milliseconds: 1300),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: SizedBox(
                    width: 1.sw,
                    height: 33.h,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: getx.Obx(
                        () => _bleData.heartValue2.value.isNotEmpty
                            ? Row(
                                children: [
                                  if (int.parse(_bleData.heartValue2.value) >=
                                          60 &&
                                      int.parse(_bleData.heartValue2.value) <=
                                          100) ...[
                                    recommendationsWidget(
                                      icon: IconManger.heart4,
                                      text: easy.tr("keepHydrated"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart1,
                                      text: easy.tr("deepBreathing"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart2,
                                      text: easy.tr("goForAWalk"),
                                    ),
                                  ] else if (int.parse(
                                          _bleData.heartValue2.value) <
                                      60) ...[
                                    recommendationsWidget(
                                      icon: IconManger.heart3,
                                      text: easy.tr("stayActive"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart4,
                                      text: easy.tr("keepHydrated"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart5,
                                      text: easy.tr("balancedDiet"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart6,
                                      text: easy.tr("monitorSymptoms"),
                                    ),
                                  ] else if (int.parse(
                                          _bleData.heartValue2.value) >
                                      100) ...[
                                    recommendationsWidget(
                                      icon: IconManger.heart7,
                                      text: easy.tr("relaxation"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart8,
                                      text: easy.tr("limitStimulants"),
                                    ),
                                    recommendationsWidget(
                                      icon: IconManger.heart9,
                                      text: easy.tr("avoidOverexertion"),
                                    ),
                                  ]
                                ],
                              )
                            : Container(),
                      ),
                    ),
                  ),
                ),
                Gap(9.h),

                DelayedDisplay(
                  delay: Duration(milliseconds: 1400),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("heartRateChart"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      Spacer(),
                      Container(
                        height: 23.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ColorManger.white,
                            width: .3,
                          ),
                          borderRadius: BorderRadius.circular(33.sp),
                        ),
                        child: DropdownButton<String>(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: 6,
                          ),
                          value: selectedItem,

                          // hint: Text(
                          //   'Select Time Period',
                          //   style: TextStyle(color: Colors.white),
                          // ),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedItem = newValue!;
                              FunctionManager.myHapticFeedback();
                              getHeartRateDataForChart(newValue);
                            });
                          },
                          onTap: () {
                            FunctionManager.myHapticFeedback();
                          },
                          underline: Container(),

                          items: items.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.sp,
                                ),
                              ),
                            );
                          }).toList(),
                          dropdownColor: Colors.black,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                DelayedDisplay(
                  delay: Duration(milliseconds: 1400),
                  slidingBeginOffset: const Offset(0.0, 0.3),
                  fadeIn: true,
                  child: Row(
                    children: [
                      MyAutoText(
                        text: easy.tr("yourHeartRateLevel"),
                        textAlign: TextAlign.start,
                        color: ColorManger.white,
                        size: 8.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ],
                  ),
                ),
                Gap(9.h),
                Expanded(
                  child: DelayedDisplay(
                    delay: Duration(milliseconds: 1500),
                    slidingBeginOffset: const Offset(0.0, 0.3),
                    fadeIn: true,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        showingTooltipIndicators: [],
                        lineTouchData: LineTouchData(
                          enabled: true, // تمكين التفاعل مع النقاط
                          handleBuiltInTouches: false, // تعطيل التفاعل التلقائي
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => ColorManger.white,
                            tooltipBorder: BorderSide(
                              color: Colors.white,
                            ), // تحديد حدود التلميح
                            getTooltipItems: (lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                return LineTooltipItem(
                                  'Value: ${spot.y}', // عرض القيمة المرتبطة بالنقطة
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(),
                          topTitles: AxisTitles(),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                            reservedSize: 20.w,
                            showTitles: true,
                            interval: 15.5,
                            getTitlesWidget: (value, meta) {
                              if (value >= meta.max) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else if (value == meta.min) {
                                return Text('');
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 1.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          )),
                          // bottomTitles: AxisTitles(
                          //   sideTitles: SideTitles(
                          //     showTitles: true,
                          //     getTitlesWidget: (value, meta) {
                          //       String title;
                          //       if (value == 0) {
                          //         title = '08/07';
                          //       } else if (value == 1) {
                          //         title = '09/07';
                          //       } else if (value == 2) {
                          //         title = '10/07';
                          //       } else if (value == 3) {
                          //         title = '11/07';
                          //       } else if (value == 4) {
                          //         title = '12/07';
                          //       } else if (value == 5) {
                          //         title = '13/07';
                          //       } else if (value == 6) {
                          //         title = '14/07';
                          //       } else {
                          //         title = '';
                          //       }
                          //       return Padding(
                          //         padding: const EdgeInsets.only(top: 8.0),
                          //         child: Text(
                          //           title,
                          //           style: TextStyle(
                          //             color: Colors.white,
                          //             fontSize: 7.sp,
                          //             fontWeight: FontWeight.bold,
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: ColorManger.transparent,
                            width: 1,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dataChart,
                            isCurved: true,

                            isStrokeCapRound: true,
                            isStrokeJoinRound: true,

                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) =>
                                  spot == FlSpot(3, 4.3),
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 7.w, // تحديد نصف القطر للنقطة
                                  color: ColorManger.redOX, // تحديد لون النقطة
                                  strokeWidth: 4.w, // سمك حدود النقطة
                                  strokeColor: ColorManger
                                      .background, // تحديد لون الحدود
                                );
                              },
                            ), // جعل النقاط تظهر

                            aboveBarData: BarAreaData(
                              spotsLine: BarAreaSpotsLine(),
                            ),

                            color: ColorManger.redHeart,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Gap(15.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getHeartRateDataForChart(String newValue) async {
    MyLoading.show(context);
    dataChart.clear();

    switch (items.indexOf(newValue)) {
      case 0:
        dataChart = await _healthRepository.getLastDayHeartRate();
        break;
      case 1:
        dataChart = await _healthRepository.getLast30DaysHeartRate();
        // dataChart = await _spo2Repository.getLast30DaysSpo2ReadingsAsFlSpot();
        break;
      case 2:
        dataChart = await _healthRepository.getLast90DaysHeartRate();
        // dataChart = await _spo2Repository.getLast90DaysSpo2ReadingsAsFlSpot();
        break;
    }
    setState(() {});
    MyLoading.dismiss();
  }

  recommendationsWidget({required String icon, required String text}) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 12.w),
      child: Row(
        children: [
          Container(
            height: 33.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(33.sp),
              border: Border.all(color: ColorManger.white),
            ),
            child: Row(
              children: [
                Container(
                  height: 33.h,
                  width: 33.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(5.6.h),
                    child: Image.asset(
                      icon,
                      height: 22.h,
                      width: 22.h,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MyAutoText(
                    text: text,
                    color: ColorManger.white,
                    size: 12.sp,
                    minFontSize: 12,
                    fontWeight: FontWeight.normal,
                    maxLine: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

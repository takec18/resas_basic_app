import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:resas_challenge_app/city/annual_municipality_tax.dart';
import 'package:resas_challenge_app/city/city.dart';

import '../env.dart';

class CityDetailPage extends StatefulWidget {
  const CityDetailPage({super.key, required this.city});

  final City city;

  @override
  State<CityDetailPage> createState() => _CityDetailPageState();
}

class _CityDetailPageState extends State<CityDetailPage> {
  late Future<String> _municipalityTaxesFuture;

  @override
  void initState() {
    super.initState();
    const host = 'opendata.resas-portal.go.jp';
    const endpoint = '/api/v1/municipality/taxes/perYear';
    final headers = {
      'X-API-KEY': Env.resasApiKey,
    };

    final param = {
      'prefCode': widget.city.prefCode.toString(),
      'cityCode': widget.city.cityCode,
    };

    _municipalityTaxesFuture = http
        .get(
          // 第三引数にパラメータを指定できます
          Uri.https(host, endpoint, param),
          headers: headers,
        )
        .then((res) => res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.city.cityName),
        ),
        body: Column(children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '一人当たり地方税',
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _municipalityTaxesFuture,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    final result = jsonDecode(snapshot.data!)['result']
                        as Map<String, dynamic>;
                    final data = result['data'] as List;
                    final items = data.cast<Map<String, dynamic>>();
                    final taxes = items
                        .map(AnnualMunicipalityTax.fromJson)
                        .toList()
                        .reversed
                        .toList();
                    return ListView.separated(
                      itemCount: taxes.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final tax = taxes[index];
                        return ListTile(
                          title: Text('${tax.year}年'),
                          trailing: Text(
                            _formatTaxLabel(tax.value),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      },
                    );
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ]));
  }

  String _formatTaxLabel(int value) {
    final formatted = NumberFormat('#,###').format(value * 1000);
    return '$formatted円';
  }
}

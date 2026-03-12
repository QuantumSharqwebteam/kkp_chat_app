// import 'package:excel/excel.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/complaints_provider.dart';
import 'package:provider/provider.dart';
import '../../widget/marketing_complaint_card.dart';

class MarketingComplaintPage extends StatelessWidget {
  const MarketingComplaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    if (Provider.of<ComplaintsProvider>(context, listen: false).status == DataStatus.loading) {
      Provider.of<ComplaintsProvider>(context, listen: true).loaddata();
    }
    return SafeArea(
      bottom: Platform.isAndroid,
      child: Scaffold(
        extendBody: false,
        appBar: AppBar(title: Text(locale.complaints)),
        body: _getBody(context),
      ),
    );
  }

  Widget _getBody(BuildContext ctx) {
    final locale = AppLocalizations.of(ctx)!;

    final provider = Provider.of<ComplaintsProvider>(ctx);
    final complaints = provider.complaints;
    final status = provider.status;

    switch (status) {
      case DataStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case DataStatus.successful:
        if (complaints?.isEmpty ?? true) {
          return Center(child: Text(locale.complaintsNotFound));
        }

        // Create a sorted copy (latest first)
        final sortedComplaints = [...complaints!]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return RefreshIndicator(
          onRefresh: () async {
            provider
              ..status = DataStatus.reloading
              ..loaddata();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            itemCount: sortedComplaints.length,
            itemBuilder: (ctx, index) {
              return MarketingComplaintCard(
                complaint: sortedComplaints[index],
              );
            },
          ),
        );

      case DataStatus.failed:
        return const Center(child: Text("Error loading"));

      case DataStatus.reloading:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

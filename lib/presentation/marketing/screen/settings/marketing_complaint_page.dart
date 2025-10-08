// import 'package:excel/excel.dart';
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
    if (Provider.of<ComplaintsProvider>(context, listen: false).status ==
        DataStatus.loading) {
      Provider.of<ComplaintsProvider>(context, listen: true).loaddata();
    }
    return Scaffold(
      appBar: AppBar(title: Text(locale.complaints)),
      body: _getBody(context),
    );
  }

  Widget _getBody(ctx) {
    final locale = AppLocalizations.of(ctx)!;
    final complaints =
        Provider.of<ComplaintsProvider>(ctx, listen: true).complaints;
    final status = Provider.of<ComplaintsProvider>(ctx, listen: true).status;
    switch (status) {
      case DataStatus.loading:
        return Center(child: CircularProgressIndicator());
      case DataStatus.successful:
        if (complaints?.isEmpty == true) {
          return Center(child: Text(locale.complaintsNotFound));
        } else {
          return RefreshIndicator(
            onRefresh: () async {
              Provider.of<ComplaintsProvider>(ctx, listen: false)
                ..status = DataStatus.reloading
                ..loaddata();
            },
            child: ListView.builder(
                itemCount: complaints!.length,
                itemBuilder: (ctx, index) {
                  return MarketingComplaintCard(complaint: complaints[index]);
                }),
          );
        }
      case DataStatus.failed:
        return Center(
          child: Text("Error loading"),
        );

      case DataStatus.reloading:
        return Center(child: CircularProgressIndicator());
    }
  }
}

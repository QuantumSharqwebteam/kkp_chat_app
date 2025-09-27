// import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/agent/complaints_provider.dart';
import 'package:provider/provider.dart';
import '../../widget/marketing_complaint_card.dart';

class MarketingComplaintPage extends StatelessWidget {
  const MarketingComplaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Provider.of<ComplaintsProvider>(context, listen: false).status ==
        DataStatus.loading) {
      Provider.of<ComplaintsProvider>(context, listen: true).loaddata();
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Complaints")),
      body: _getBody(context),
    );
  }

  Widget _getBody(ctx) {
    final complaints =
        Provider.of<ComplaintsProvider>(ctx, listen: true).complaints;
    final status = Provider.of<ComplaintsProvider>(ctx, listen: true).status;
    switch (status) {
      case DataStatus.loading:
        return Center(child: CircularProgressIndicator());
      case DataStatus.successful:
        if (complaints?.isEmpty == true) {
          return Center(child: Text('Complaints not found'));
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
        // TODO: Handle this case.
        throw UnimplementedError();
      case DataStatus.reloading:
        return Center(child: CircularProgressIndicator());
    }
  }
}

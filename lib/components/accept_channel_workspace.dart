import 'package:flutter/material.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';


class AcceptChannelWorkspace extends StatelessWidget{
  final isChannel;
  final otherUser;
  final inviteChannel;
  final inviteWorkspace;
  final members;
  final id;

  AcceptChannelWorkspace({
    Key? key,
    @required this.inviteChannel,
    @required this.isChannel,
    @required this.otherUser,
    @required this.inviteWorkspace,
    this.members,
    this.id
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false );
    final isDark = auth.theme == ThemeType.DARK;
    final onlines = members.where((element) => element["is_online"] == true).length;
    final user = Provider.of<User>(context, listen: false).currentUser;
    return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(width: 0.5, color: Colors.white70 )),
        backgroundColor: isDark ? Color(0xff323f4b) : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: 192,
          width: 400,
          // decoration: BoxDecoration(border: Border.all(width: 1)),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 24,bottom: 15),
                alignment: Alignment.center,
                child: Text(S.current.receiveJoinChannel(isChannel ? "CHANNEL" : "WORKSPACE"), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 18),
                padding: EdgeInsets.only(left: 48,top: 10),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.amber
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 25),
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isChannel ? inviteChannel["name"] : inviteWorkspace["name"], style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                child: Row(
                                  children: [
                                    Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.green),width: 10, height: 10 ),
                                    SizedBox(width: 8),
                                    Text("$onlines online")
                                  ],
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                child: Row(
                                  children: [
                                    Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.grey[400]),width: 10, height: 10 ),
                                    SizedBox(width: 8),
                                    Text("${members.length} member")
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 46,
                  color: isDark ? Color(0xff1f2933) : Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: Container(
                          width: 168,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(width: 0.5, color: Color(0xffff7875)),
                            borderRadius: BorderRadius.circular(2),
                            // boxShadow: [BoxShadow(color: Color(0xff000000))],
                            color: isDark ? Colors.transparent : Color(0xfffff1f0)
                          ),
                          alignment: Alignment.center,
                          child: Text(S.current.cancel, style: TextStyle(color: isDark ? Color(0xffff7875) : Color(0xffff7875)),),
                        ),
                        onPressed: () async{
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: Container(
                          width: 168,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            // boxShadow: [BoxShadow(color: Color(0xff000000))],
                            color: isDark ? Color(0xff19dfcb) : Color(0xff2a5298)
                          ),
                          alignment: Alignment.center,
                          child: Text(S.current.accept, style: TextStyle(color: isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white)),
                        ),
                        onPressed: () async{
                        //  Navigator.pop(context);
                          if(isChannel){
                            Provider.of<Channels>(context, listen: false).joinChannelByInvitation(auth.token, this.inviteWorkspace["workspace_id"], this.inviteChannel["channel_id"], otherUser, this.id).then((value) =>
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(value),
                                ),
                              )
                            );
                          }
                          else
                            await Provider.of<Workspaces>(context,listen: false).joinWorkspaceByInvitation(auth.token, this.inviteWorkspace["workspace_id"], user["email"], 1, otherUser, this.id).then((value) =>
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(value),
                              ),
                            )
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
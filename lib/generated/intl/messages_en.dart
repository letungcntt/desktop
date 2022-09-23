// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(fullName) => "${fullName} has assign you in an issue";

  static String m1(time) => "  at ${time}";

  static String m2(name) =>
      "There aren\'t any actions for you to take on ${name}.";

  static String m3(name) => "${name} has changed avatar this group";

  static String m4(assignUser, issueauthor, channelName) =>
      "${assignUser} has closed an issue ${issueauthor} created in ${channelName} channel";

  static String m5(assignUser, channelName) =>
      "${assignUser} has closed an issue you has been assign in ${channelName} channel";

  static String m6(count) => "${count} Closed";

  static String m7(time) => "commented ${time}";

  static String m8(count) =>
      "${Intl.plural(count, one: ' 1 comment', other: ' ${count} comments')}";

  static String m9(count) =>
      "${Intl.plural(count, one: '1 day ago', other: '${count} days ago')}";

  static String m10(count) =>
      "${Intl.plural(count, one: '1 hour ago', other: '${count} hours ago')}";

  static String m11(count) => "${count} labels";

  static String m12(count) =>
      "${Intl.plural(count, one: '1 minute ago', other: '${count} minutes ago')}";

  static String m13(count) =>
      "${Intl.plural(count, one: '1 month ago', other: '${count} months ago')}";

  static String m14(count) =>
      "${Intl.plural(count, one: '1 year ago', other: '${count} years ago')}";

  static String m15(name) => "Are you sure you want to archive ${name}?";

  static String m16(name) => "Search your contacts and message in ${name}";

  static String m17(name) => "Search messages in ${name}";

  static String m18(time) => "•  edited ${time}";

  static String m19(statusCode) => "${statusCode} Error with status:";

  static String m20(user, invitedUser) => " ${user} has invited ${invitedUser}";

  static String m21(fullName, channelName) =>
      "${fullName} has invite you to ${channelName} channel";

  static String m22(fullName, workspaceName) =>
      "${fullName} has invite you to ${workspaceName} workspace";

  static String m23(name) => "Invite to ${name}";

  static String m24(count) => "${count} Open";

  static String m25(count) => "${count} Milestones";

  static String m26(time) => "opened this issue ${time}.";

  static String m27(name) => "Option: ${name}";

  static String m28(type) => "YOU RECEIVE AN INVITE TO JOIN A ${type}";

  static String m29(assignUser, issueauthor, channelName) =>
      "${assignUser} has reopened an issue ${issueauthor} created in ${channelName} channel";

  static String m30(assignUser, channelName) =>
      "${assignUser} has reopened an issue you has been assign in ${channelName} channel";

  static String m31(hotkey) =>
      "Search (${hotkey} + F) / Anything (${hotkey} + T)";

  static String m32(type) => "Search ${type}";

  static String m33(count) => "sent ${count} files.";

  static String m34(count) => "sent ${count} images.";

  static String m35(count) => "sent ${count} videos.";

  static String m36(count) => "Show ${count} more comments";

  static String m37(character) => "${character} Sticker";

  static String m38(fullName) => "${fullName} has unassign you in an issue";

  static String m39(hotkey) =>
      "Tip: Use shotkeyboard ${hotkey}-T to quick search";

  static String m40(hotkey) =>
      "Tip: Use shotkeyboard ${hotkey}-T to search anything";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "accept": MessageLookupByLibrary.simpleMessage("Accept"),
        "acceptInvite": MessageLookupByLibrary.simpleMessage("Accepted"),
        "accepted": MessageLookupByLibrary.simpleMessage("Accepted"),
        "active": MessageLookupByLibrary.simpleMessage("Active"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addCommands": MessageLookupByLibrary.simpleMessage("Add commands"),
        "addDescription":
            MessageLookupByLibrary.simpleMessage("Add description"),
        "addDetail":
            MessageLookupByLibrary.simpleMessage("Add a more detailed..."),
        "addFriend": MessageLookupByLibrary.simpleMessage("Add friend"),
        "addFriendUsingEmail": MessageLookupByLibrary.simpleMessage(
            "Try adding a friend using their username or email address"),
        "addList": MessageLookupByLibrary.simpleMessage("Add list"),
        "addName": MessageLookupByLibrary.simpleMessage("Add name"),
        "addNewApp": MessageLookupByLibrary.simpleMessage("Add new apps"),
        "addNewList": MessageLookupByLibrary.simpleMessage("Add new list"),
        "addNewOption": MessageLookupByLibrary.simpleMessage("Add new option"),
        "addParamsCommands":
            MessageLookupByLibrary.simpleMessage("Add Params Commands"),
        "addShortcut": MessageLookupByLibrary.simpleMessage("/ Add shortcut"),
        "addText": MessageLookupByLibrary.simpleMessage("Add text"),
        "addTitle": MessageLookupByLibrary.simpleMessage("Add title"),
        "addUrl": MessageLookupByLibrary.simpleMessage("https:// Add url"),
        "added": MessageLookupByLibrary.simpleMessage("Added"),
        "ago": MessageLookupByLibrary.simpleMessage("ago"),
        "all": MessageLookupByLibrary.simpleMessage("All"),
        "appAvailable":
            MessageLookupByLibrary.simpleMessage("Applications are available"),
        "appDefault": MessageLookupByLibrary.simpleMessage("App default"),
        "appName": MessageLookupByLibrary.simpleMessage("App Name"),
        "apps": MessageLookupByLibrary.simpleMessage("Apps"),
        "archiveChannel":
            MessageLookupByLibrary.simpleMessage("Archive Channel"),
        "askDeleteMember": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete this member?"),
        "askLeaveWorkspace": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to leave this workspace?"),
        "assignIssue": m0,
        "assignedNobody":
            MessageLookupByLibrary.simpleMessage("Assigned to nobody"),
        "assignees": MessageLookupByLibrary.simpleMessage("Assignees"),
        "at": m1,
        "attachImageToComment":
            MessageLookupByLibrary.simpleMessage("Attach image to comment"),
        "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
        "author": MessageLookupByLibrary.simpleMessage("Author"),
        "auto": MessageLookupByLibrary.simpleMessage("Auto"),
        "back": MessageLookupByLibrary.simpleMessage("Back"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "block": MessageLookupByLibrary.simpleMessage("Block"),
        "blocked": MessageLookupByLibrary.simpleMessage("Blocked"),
        "call": MessageLookupByLibrary.simpleMessage("Call"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cantActionsForYou": m2,
        "changeAvatar": MessageLookupByLibrary.simpleMessage("Change Avatar"),
        "changeAvatarDm": m3,
        "changeFile": MessageLookupByLibrary.simpleMessage("Change File"),
        "changeNickname":
            MessageLookupByLibrary.simpleMessage("Change Nickname"),
        "changeWorkflow":
            MessageLookupByLibrary.simpleMessage("Change workflow"),
        "channel": MessageLookupByLibrary.simpleMessage("Channel"),
        "channelInstalled":
            MessageLookupByLibrary.simpleMessage("Channel Installed"),
        "channelName": MessageLookupByLibrary.simpleMessage("Channel Name"),
        "channelNameExisted":
            MessageLookupByLibrary.simpleMessage("Channel name already exists"),
        "channelType": MessageLookupByLibrary.simpleMessage("Channel Type"),
        "channels": MessageLookupByLibrary.simpleMessage("Channels"),
        "closeIssue": MessageLookupByLibrary.simpleMessage("Close issue"),
        "closeIssues": m4,
        "closeIssues1": m5,
        "closeWithComment":
            MessageLookupByLibrary.simpleMessage("Close with comment"),
        "closed": m6,
        "codeInvite": MessageLookupByLibrary.simpleMessage("Code invite"),
        "color": MessageLookupByLibrary.simpleMessage("Color"),
        "colorPicker": MessageLookupByLibrary.simpleMessage("Color Picker"),
        "commands": MessageLookupByLibrary.simpleMessage("Commands"),
        "comment": MessageLookupByLibrary.simpleMessage("Comment"),
        "commented": m7,
        "communityGuide":
            MessageLookupByLibrary.simpleMessage("Community Guidelines"),
        "complete": MessageLookupByLibrary.simpleMessage("complete"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "connectGoogleDrive":
            MessageLookupByLibrary.simpleMessage("Connect Google Drive"),
        "connectPOSApp": MessageLookupByLibrary.simpleMessage(
            "Connect the POS app to this channel"),
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "conversationName":
            MessageLookupByLibrary.simpleMessage("Conversation name"),
        "copyToClipboard":
            MessageLookupByLibrary.simpleMessage("Copy to clipboard"),
        "countComments": m8,
        "countDayAgo": m9,
        "countHourAgo": m10,
        "countLabels": m11,
        "countMinuteAgo": m12,
        "countMonthAgo": m13,
        "countYearAgo": m14,
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createApp": MessageLookupByLibrary.simpleMessage("Create app"),
        "createBy": MessageLookupByLibrary.simpleMessage("Create by"),
        "createChannel": MessageLookupByLibrary.simpleMessage("Create Channel"),
        "createCommand": MessageLookupByLibrary.simpleMessage("Create command"),
        "createCommands":
            MessageLookupByLibrary.simpleMessage("Create commands"),
        "createCustomApp":
            MessageLookupByLibrary.simpleMessage("Create custom app"),
        "createGroup": MessageLookupByLibrary.simpleMessage("Create group"),
        "createLabels": MessageLookupByLibrary.simpleMessage("Create label"),
        "createMilestone":
            MessageLookupByLibrary.simpleMessage("Create milestone"),
        "createNewBoard":
            MessageLookupByLibrary.simpleMessage("Create new board"),
        "createWorkspace":
            MessageLookupByLibrary.simpleMessage("Create a workspace."),
        "customApp": MessageLookupByLibrary.simpleMessage("Create custom apps"),
        "dark": MessageLookupByLibrary.simpleMessage("Dark"),
        "dateOfBirth": MessageLookupByLibrary.simpleMessage("Date of birth"),
        "day": MessageLookupByLibrary.simpleMessage("day"),
        "days": MessageLookupByLibrary.simpleMessage("days"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteChannel": MessageLookupByLibrary.simpleMessage("Delete Channel"),
        "deleteChat": MessageLookupByLibrary.simpleMessage("Delete chat"),
        "deleteComment":
            MessageLookupByLibrary.simpleMessage("Delete this comment?"),
        "deleteForEveryone":
            MessageLookupByLibrary.simpleMessage("Delete for everyone"),
        "deleteForMe": MessageLookupByLibrary.simpleMessage("Delete for me"),
        "deleteLabel": MessageLookupByLibrary.simpleMessage("Delete Label"),
        "deleteMembers": MessageLookupByLibrary.simpleMessage("Delete member?"),
        "deleteMessages":
            MessageLookupByLibrary.simpleMessage("Delete Messages"),
        "deleteMilestone":
            MessageLookupByLibrary.simpleMessage("Delete Milestone"),
        "deleteThisMessages": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete this message?"),
        "deleteWorkspace":
            MessageLookupByLibrary.simpleMessage("Delete workspace"),
        "desAddFriend": MessageLookupByLibrary.simpleMessage(
            "Enter your friend\'s name with their tag. Ex: JohnDoe#1234"),
        "desApp": MessageLookupByLibrary.simpleMessage(
            "After creating and installing the application, you can configure to stay in specific channels."),
        "desBankApp": MessageLookupByLibrary.simpleMessage(
            "Notice of bank account fluctuations."),
        "desDeleteChannel": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to delete this member from channel?\nThis action cannot be undone."),
        "desMentionMode": MessageLookupByLibrary.simpleMessage(
            "Channel dimming, highlighting and notification only when @mentions or @all."),
        "desNormalMode": MessageLookupByLibrary.simpleMessage(
            "All messages have notifications and highlights."),
        "desOffMode": MessageLookupByLibrary.simpleMessage("Nothing."),
        "desPOSApp": MessageLookupByLibrary.simpleMessage(
            "Synchronize messages from the left side configuration POS."),
        "desSearch": MessageLookupByLibrary.simpleMessage(
            "Search your contacts and messages in direct"),
        "desSearchAnything": MessageLookupByLibrary.simpleMessage(
            "Search all your contacts and messages."),
        "desSilentMode": MessageLookupByLibrary.simpleMessage(
            "Turn off notifications only."),
        "descArchiveChannel": m15,
        "descCreateWorkspace": MessageLookupByLibrary.simpleMessage(
            "Your workspace is where you and your friends hang out. Make your and start talking."),
        "descDeleteLabel": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to delete miletsone?\nThis action cannot be undone."),
        "descDeleteMilestone": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to delete miletsone?\nThis action cannot be undone."),
        "descDeleteNewsroom": MessageLookupByLibrary.simpleMessage(
            "This is channel newsroom, if you remove this user from the channel it will be removed from the workspace"),
        "descDeleteWorkspace": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to delete workspace ? This action cannot be undone"),
        "descFileterAuthor":
            MessageLookupByLibrary.simpleMessage("Type or choose a name"),
        "descInvite": MessageLookupByLibrary.simpleMessage(
            "Invite existing team member or add new ones."),
        "descJoinWs": MessageLookupByLibrary.simpleMessage(
            "Enter an invite below to join an existing workspace"),
        "descLeaveChannel": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to leave channel?\nThis action cannot be undone."),
        "descLeaveGroup": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to leave this conversation?"),
        "descLeaveWorkspace": MessageLookupByLibrary.simpleMessage(
            "Are you sure want to leave workspace?\nThis action cannot be undone."),
        "descNothingTurnedUp": MessageLookupByLibrary.simpleMessage(
            "You may want to try using different keywords or checking for typos"),
        "descResetDeviceKey": MessageLookupByLibrary.simpleMessage(
            "**Tap Reset Device Key to remove data from other devices. Panchat will send a Vertify Code to your email/phone number"),
        "descSearchAll": MessageLookupByLibrary.simpleMessage(
            "Search all your directs and all workspaces"),
        "descSearchContact":
            MessageLookupByLibrary.simpleMessage("Search all your contacts"),
        "descSearchDms": MessageLookupByLibrary.simpleMessage(
            "Search messages in your direct"),
        "descSearchInCtWs": m16,
        "descSearchInWs": m17,
        "descSyncPanchat": MessageLookupByLibrary.simpleMessage(
            "*Tap Sync Data and open Panchat app on your devices to get OTP code"),
        "descWatchActivity": MessageLookupByLibrary.simpleMessage(
            "Notified of all notifications on this channel."),
        "descWatchMention": MessageLookupByLibrary.simpleMessage(
            "Only receive notifications from this channel when participating or @mentioned."),
        "description": MessageLookupByLibrary.simpleMessage("Description"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "devices": MessageLookupByLibrary.simpleMessage("Devices"),
        "directMessages":
            MessageLookupByLibrary.simpleMessage("Direct Messages"),
        "directSettings":
            MessageLookupByLibrary.simpleMessage("Direct settings"),
        "displayName": MessageLookupByLibrary.simpleMessage("Display name"),
        "dueBy": MessageLookupByLibrary.simpleMessage("Due by "),
        "dueDate": MessageLookupByLibrary.simpleMessage("Due date (Opt)"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editChannelDesc":
            MessageLookupByLibrary.simpleMessage("Edit channel description"),
        "editChannelTopic":
            MessageLookupByLibrary.simpleMessage("Edit channel topic"),
        "editComment": MessageLookupByLibrary.simpleMessage("Edit comment"),
        "editImage": MessageLookupByLibrary.simpleMessage("Edit Image"),
        "edited": MessageLookupByLibrary.simpleMessage("•  edited"),
        "editedBy": MessageLookupByLibrary.simpleMessage("•  edited by"),
        "editedTime": m18,
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailAddress": MessageLookupByLibrary.simpleMessage("Email address"),
        "enjoyToSearch":
            MessageLookupByLibrary.simpleMessage("Enjoy to search"),
        "enterListTitle":
            MessageLookupByLibrary.simpleMessage("Enter list title"),
        "enterPassToTransfer":
            MessageLookupByLibrary.simpleMessage("Enter password to transfer"),
        "enterUsername":
            MessageLookupByLibrary.simpleMessage("Enter a Username#0000"),
        "errorWithStatus": m19,
        "example": MessageLookupByLibrary.simpleMessage("Examples"),
        "female": MessageLookupByLibrary.simpleMessage("Female"),
        "fileDownloading":
            MessageLookupByLibrary.simpleMessage("File downloading"),
        "fileManager": MessageLookupByLibrary.simpleMessage("File manager"),
        "files": MessageLookupByLibrary.simpleMessage("Files"),
        "filterLabels": MessageLookupByLibrary.simpleMessage("Filter labels"),
        "filterMilestone":
            MessageLookupByLibrary.simpleMessage("Filter milestones"),
        "filterNoMilestone":
            MessageLookupByLibrary.simpleMessage("Issues with no milestone"),
        "findAll": MessageLookupByLibrary.simpleMessage(
            "Find workspace, message, contacts ..."),
        "findEverything":
            MessageLookupByLibrary.simpleMessage("Find everything for you."),
        "forwardMessage":
            MessageLookupByLibrary.simpleMessage("Forward message"),
        "forwardThisMessage":
            MessageLookupByLibrary.simpleMessage("Share this message"),
        "friends": MessageLookupByLibrary.simpleMessage("Friends"),
        "fullName": MessageLookupByLibrary.simpleMessage("Full Name"),
        "gender": MessageLookupByLibrary.simpleMessage("Gender"),
        "haveAnInviteAlready":
            MessageLookupByLibrary.simpleMessage("Have an invite already?"),
        "hour": MessageLookupByLibrary.simpleMessage("hour"),
        "hours": MessageLookupByLibrary.simpleMessage("hours"),
        "images": MessageLookupByLibrary.simpleMessage("Images"),
        "inThread": MessageLookupByLibrary.simpleMessage("In thread"),
        "incomingFriendRequest":
            MessageLookupByLibrary.simpleMessage("Incoming Friend Request"),
        "index": MessageLookupByLibrary.simpleMessage("Index:"),
        "inputCannotEmpty":
            MessageLookupByLibrary.simpleMessage("Input cannot be empty"),
        "insertKeyCodeChannel": MessageLookupByLibrary.simpleMessage(
            "Please Insert KeyCode Channel"),
        "install": MessageLookupByLibrary.simpleMessage("Install"),
        "invied": m20,
        "inviedChannel": m21,
        "inviedChannels":
            MessageLookupByLibrary.simpleMessage(" Has invite you to channel"),
        "inviedWorkSpace": m22,
        "invitationHistory":
            MessageLookupByLibrary.simpleMessage("Invitation history:"),
        "invite": MessageLookupByLibrary.simpleMessage("Invite"),
        "inviteCodeWs": MessageLookupByLibrary.simpleMessage(
            "Or Invite by Code Workspace: "),
        "inviteLookLike":
            MessageLookupByLibrary.simpleMessage("Invites should look like"),
        "invitePeople": MessageLookupByLibrary.simpleMessage("Invite People"),
        "inviteTo": m23,
        "inviteToChannel": MessageLookupByLibrary.simpleMessage(
            "Invite new people to this channel."),
        "inviteToGroup":
            MessageLookupByLibrary.simpleMessage("Invite to group"),
        "inviteToWorkspace":
            MessageLookupByLibrary.simpleMessage("Invite to workspace"),
        "inviteWsCode":
            MessageLookupByLibrary.simpleMessage("INVITE LINK OR CODE INVITE"),
        "invited": MessageLookupByLibrary.simpleMessage("Invited"),
        "issue": MessageLookupByLibrary.simpleMessage("Issue"),
        "issueCreateSuccess":
            MessageLookupByLibrary.simpleMessage("Issue created successfully"),
        "issues": MessageLookupByLibrary.simpleMessage("Issues"),
        "join": MessageLookupByLibrary.simpleMessage("Join"),
        "joinChannel": MessageLookupByLibrary.simpleMessage("Join Channel"),
        "joinChannelFail": MessageLookupByLibrary.simpleMessage(
            "Join the error channel. Please try again.."),
        "joinChannelSuccess": MessageLookupByLibrary.simpleMessage(
            "Join channel was successful."),
        "joinWorkspace":
            MessageLookupByLibrary.simpleMessage("Join a workspace"),
        "joinWorkspaceFail": MessageLookupByLibrary.simpleMessage(
            "Join the error workspace. Please try again.."),
        "joinWorkspaceSuccess": MessageLookupByLibrary.simpleMessage(
            "Join workspace was successful"),
        "labels": MessageLookupByLibrary.simpleMessage("Labels"),
        "language": MessageLookupByLibrary.simpleMessage("Language & Region"),
        "languages": MessageLookupByLibrary.simpleMessage("Languages"),
        "leastRecentlyUpdated":
            MessageLookupByLibrary.simpleMessage("Least Recently Updated"),
        "leaveChannel": MessageLookupByLibrary.simpleMessage("Leave Channel"),
        "leaveDirect":
            MessageLookupByLibrary.simpleMessage("Has left this conversation"),
        "leaveGroup": MessageLookupByLibrary.simpleMessage("Leave group"),
        "leaveWorkspace":
            MessageLookupByLibrary.simpleMessage("Leave workspace"),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "listArchive": MessageLookupByLibrary.simpleMessage("List Archived"),
        "listChannel": MessageLookupByLibrary.simpleMessage("List channel"),
        "listWorkspaceMember": MessageLookupByLibrary.simpleMessage(
            "List of people in the workspace"),
        "loggedIntoGoogleDrive":
            MessageLookupByLibrary.simpleMessage("Logged into Google Drive"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "lookingFor":
            MessageLookupByLibrary.simpleMessage("Or I\'m looking for..."),
        "male": MessageLookupByLibrary.simpleMessage("Male"),
        "markAsUnread": MessageLookupByLibrary.simpleMessage("Mark as unread"),
        "members": MessageLookupByLibrary.simpleMessage("Members"),
        "mentionMode": MessageLookupByLibrary.simpleMessage("MENTION MODE"),
        "mentions": MessageLookupByLibrary.simpleMessage("Mentions"),
        "messages": MessageLookupByLibrary.simpleMessage("Messages"),
        "milestones": MessageLookupByLibrary.simpleMessage("Milestones"),
        "minute": MessageLookupByLibrary.simpleMessage("minute"),
        "minutes": MessageLookupByLibrary.simpleMessage("minutes"),
        "momentAgo": MessageLookupByLibrary.simpleMessage("moment ago"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "months": MessageLookupByLibrary.simpleMessage("months"),
        "moreUnread": MessageLookupByLibrary.simpleMessage("More unreads"),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "nameFile": MessageLookupByLibrary.simpleMessage("Name file: "),
        "newIssue": MessageLookupByLibrary.simpleMessage("New issue"),
        "newLabel": MessageLookupByLibrary.simpleMessage("New label"),
        "newMilestone": MessageLookupByLibrary.simpleMessage("New milestone"),
        "newest": MessageLookupByLibrary.simpleMessage("Newest"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "noDescriptionProvided":
            MessageLookupByLibrary.simpleMessage("_No description provided._"),
        "noFriendToAdd":
            MessageLookupByLibrary.simpleMessage("No friends to add"),
        "normalMode": MessageLookupByLibrary.simpleMessage("NORMAL MODE"),
        "noteCreateWs": MessageLookupByLibrary.simpleMessage(
            "By create a workspace, you agree to Pancake\'s"),
        "nothingTurnedUp":
            MessageLookupByLibrary.simpleMessage("Nothing turned up"),
        "notifySetting":
            MessageLookupByLibrary.simpleMessage("Notification setting"),
        "offMode": MessageLookupByLibrary.simpleMessage("OFF MODE"),
        "offline": MessageLookupByLibrary.simpleMessage("Offline"),
        "oldest": MessageLookupByLibrary.simpleMessage("Oldest"),
        "on": MessageLookupByLibrary.simpleMessage("on"),
        "online": MessageLookupByLibrary.simpleMessage("Online"),
        "open": m24,
        "openMilestones": m25,
        "openThisIssue": m26,
        "option": MessageLookupByLibrary.simpleMessage("Option"),
        "optionName": m27,
        "or": MessageLookupByLibrary.simpleMessage("or"),
        "outgoingFriendRequest":
            MessageLookupByLibrary.simpleMessage("Outgoing Friend Request"),
        "params": MessageLookupByLibrary.simpleMessage("Params:"),
        "paramsCommand":
            MessageLookupByLibrary.simpleMessage("Params Commands:"),
        "pastDueBy": MessageLookupByLibrary.simpleMessage("Past due by"),
        "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone number"),
        "pinMessages": MessageLookupByLibrary.simpleMessage("Pin messages"),
        "pinThisChannel":
            MessageLookupByLibrary.simpleMessage("Pin this channel."),
        "pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
        "pleaseSelectChannel":
            MessageLookupByLibrary.simpleMessage("Please select channel"),
        "pleaseUpdateVersion":
            MessageLookupByLibrary.simpleMessage("Please update version"),
        "pollIsDisabled":
            MessageLookupByLibrary.simpleMessage("This poll is disabled"),
        "preview": MessageLookupByLibrary.simpleMessage("Preview"),
        "previewComment":
            MessageLookupByLibrary.simpleMessage("Preview Comment"),
        "previewText": MessageLookupByLibrary.simpleMessage("Preview text"),
        "previous": MessageLookupByLibrary.simpleMessage("Previous"),
        "private": MessageLookupByLibrary.simpleMessage("Private"),
        "receiveJoinChannel": m28,
        "recentChannel": MessageLookupByLibrary.simpleMessage("Recent channel"),
        "recentlyUpdated":
            MessageLookupByLibrary.simpleMessage("Recently Updated"),
        "regular": MessageLookupByLibrary.simpleMessage("Regular"),
        "reject": MessageLookupByLibrary.simpleMessage("Reject"),
        "removeFriend": MessageLookupByLibrary.simpleMessage("Remove Friend"),
        "removeFromSavedItems":
            MessageLookupByLibrary.simpleMessage("Remove from saved items"),
        "reopen": MessageLookupByLibrary.simpleMessage("Reopen"),
        "reopenIssue": MessageLookupByLibrary.simpleMessage("Reopen issue"),
        "reopened": m29,
        "reopened1": m30,
        "reply": MessageLookupByLibrary.simpleMessage("replied to a message"),
        "requestUrl": MessageLookupByLibrary.simpleMessage("Request URL:"),
        "resetDeviceKey":
            MessageLookupByLibrary.simpleMessage("Reset device key **"),
        "response": MessageLookupByLibrary.simpleMessage("Response"),
        "restore": MessageLookupByLibrary.simpleMessage("Restore"),
        "results": MessageLookupByLibrary.simpleMessage("Results"),
        "roles": MessageLookupByLibrary.simpleMessage("Roles"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveChanges": MessageLookupByLibrary.simpleMessage("Save change"),
        "savedMessages": MessageLookupByLibrary.simpleMessage("Saved Messages"),
        "searchAnything": m31,
        "searchChannel": MessageLookupByLibrary.simpleMessage("Search Channel"),
        "searchMember": MessageLookupByLibrary.simpleMessage("Search member"),
        "searchType": m32,
        "selectChannel": MessageLookupByLibrary.simpleMessage("Select Channel"),
        "selectMember": MessageLookupByLibrary.simpleMessage("Select member"),
        "sent": MessageLookupByLibrary.simpleMessage("Sent"),
        "sentAFile": MessageLookupByLibrary.simpleMessage("sent a file."),
        "sentAVideo": MessageLookupByLibrary.simpleMessage("sent a video."),
        "sentAnImage": MessageLookupByLibrary.simpleMessage("sent an image."),
        "sentAttachments":
            MessageLookupByLibrary.simpleMessage("sent attachments."),
        "sentFiles": m33,
        "sentImages": m34,
        "sentVideos": m35,
        "setAdmin": MessageLookupByLibrary.simpleMessage("Set Admin"),
        "setDesc": MessageLookupByLibrary.simpleMessage("Set Description"),
        "setEditor": MessageLookupByLibrary.simpleMessage("Set Editor"),
        "setMember": MessageLookupByLibrary.simpleMessage("Set Member"),
        "setTopic": MessageLookupByLibrary.simpleMessage("Set Topic"),
        "setrole": MessageLookupByLibrary.simpleMessage("Set Roles"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "share": MessageLookupByLibrary.simpleMessage("Sent a shared message"),
        "shareMessage":
            MessageLookupByLibrary.simpleMessage("Sharing this message:"),
        "shortcut": MessageLookupByLibrary.simpleMessage("Shortcut:"),
        "showMoreComments": m36,
        "silentMode": MessageLookupByLibrary.simpleMessage("SILENT MODE"),
        "sort": MessageLookupByLibrary.simpleMessage("Sort"),
        "sortBy": MessageLookupByLibrary.simpleMessage("Sort by"),
        "startingUp": MessageLookupByLibrary.simpleMessage("Starting up"),
        "sticker": m37,
        "sticker1": MessageLookupByLibrary.simpleMessage("Sent a sticker"),
        "submit": MessageLookupByLibrary.simpleMessage("Submit"),
        "submitNewIssue":
            MessageLookupByLibrary.simpleMessage("Submit new issue"),
        "success": MessageLookupByLibrary.simpleMessage("Success"),
        "sync": MessageLookupByLibrary.simpleMessage("Sync"),
        "syncPanchatApp":
            MessageLookupByLibrary.simpleMessage("Sync by Panchat app *"),
        "syntaxError": MessageLookupByLibrary.simpleMessage(
            "Syntax code was wrong, try again!"),
        "tClose": MessageLookupByLibrary.simpleMessage("Close"),
        "tClosed": MessageLookupByLibrary.simpleMessage("Closed"),
        "tOpen": MessageLookupByLibrary.simpleMessage("Open"),
        "tagName": MessageLookupByLibrary.simpleMessage("Tag name"),
        "theVideoCallEnded":
            MessageLookupByLibrary.simpleMessage("The video call ended."),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "thisMessageDeleted":
            MessageLookupByLibrary.simpleMessage("[This message was deleted.]"),
        "threads": MessageLookupByLibrary.simpleMessage("Threads"),
        "timeCreated": MessageLookupByLibrary.simpleMessage("Time Created"),
        "tipFilter":
            MessageLookupByLibrary.simpleMessage("Use ↑ ↓ ↵ to navigate"),
        "tipSearch": MessageLookupByLibrary.simpleMessage(
            "Tips: Use shotkeyboard CMD + T to search anything."),
        "title": MessageLookupByLibrary.simpleMessage("Title"),
        "topic": MessageLookupByLibrary.simpleMessage("Topic"),
        "transfer": MessageLookupByLibrary.simpleMessage("Transfer"),
        "transferIssue": MessageLookupByLibrary.simpleMessage("Transfer issue"),
        "transferOwner":
            MessageLookupByLibrary.simpleMessage("Transfer ownership"),
        "transferTo": MessageLookupByLibrary.simpleMessage("Transfer to"),
        "typeEmailOrPhoneToInvite": MessageLookupByLibrary.simpleMessage(
            "Type an email or phone number to invite"),
        "typeMessage":
            MessageLookupByLibrary.simpleMessage("Type a message..."),
        "unPinThisChannel":
            MessageLookupByLibrary.simpleMessage("Unpin this channel."),
        "unassignIssue": m38,
        "unreadOnly": MessageLookupByLibrary.simpleMessage("Unread only"),
        "unwatch": MessageLookupByLibrary.simpleMessage("Unwatch"),
        "updateCommand": MessageLookupByLibrary.simpleMessage("Update command"),
        "updateComment": MessageLookupByLibrary.simpleMessage("Update comment"),
        "upload": MessageLookupByLibrary.simpleMessage("Upload"),
        "useShotKeyboardQuickSearch": m39,
        "useShotKeyboardSearchAnything": m40,
        "userProfile": MessageLookupByLibrary.simpleMessage("User profile"),
        "videoCall": MessageLookupByLibrary.simpleMessage("Video"),
        "watch": MessageLookupByLibrary.simpleMessage("Watch"),
        "watchActivity": MessageLookupByLibrary.simpleMessage("All Activity"),
        "watchAllComment": MessageLookupByLibrary.simpleMessage(
            "Add all comments from the subcribed issues to the thread."),
        "watchMention":
            MessageLookupByLibrary.simpleMessage("Participating and @mentions"),
        "whatForDiscussion":
            MessageLookupByLibrary.simpleMessage("What’s up for discussion?"),
        "workspace": MessageLookupByLibrary.simpleMessage("Workspace"),
        "workspaceCannotBlank": MessageLookupByLibrary.simpleMessage(
            "Workspaces\'s name cannot be blank"),
        "workspaceName":
            MessageLookupByLibrary.simpleMessage("Workspace\'s name"),
        "year": MessageLookupByLibrary.simpleMessage("year"),
        "years": MessageLookupByLibrary.simpleMessage("years"),
        "yourFriend": MessageLookupByLibrary.simpleMessage("Your friends"),
        "yourName": MessageLookupByLibrary.simpleMessage("Your name"),
        "yourRoleCannotAction": MessageLookupByLibrary.simpleMessage(
            "Your role cannot take action.")
      };
}

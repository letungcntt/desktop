// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `{count, plural, one{1 year ago} other{{count} years ago}}`
  String countYearAgo(num count) {
    return Intl.plural(
      count,
      one: '1 year ago',
      other: '$count years ago',
      name: 'countYearAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 month ago} other{{count} months ago}}`
  String countMonthAgo(num count) {
    return Intl.plural(
      count,
      one: '1 month ago',
      other: '$count months ago',
      name: 'countMonthAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 day ago} other{{count} days ago}}`
  String countDayAgo(num count) {
    return Intl.plural(
      count,
      one: '1 day ago',
      other: '$count days ago',
      name: 'countDayAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 hour ago} other{{count} hours ago}}`
  String countHourAgo(num count) {
    return Intl.plural(
      count,
      one: '1 hour ago',
      other: '$count hours ago',
      name: 'countHourAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 minute ago} other{{count} minutes ago}}`
  String countMinuteAgo(num count) {
    return Intl.plural(
      count,
      one: '1 minute ago',
      other: '$count minutes ago',
      name: 'countMinuteAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{ 1 comment} other{ {count} comments}}`
  String countComments(num count) {
    return Intl.plural(
      count,
      one: ' 1 comment',
      other: ' $count comments',
      name: 'countComments',
      desc: '',
      args: [count],
    );
  }

  /// `moment ago`
  String get momentAgo {
    return Intl.message(
      'moment ago',
      name: 'momentAgo',
      desc: '',
      args: [],
    );
  }

  /// `Language & Region`
  String get language {
    return Intl.message(
      'Language & Region',
      name: 'language',
      desc: '',
      args: [],
    );
  }

  /// `User profile`
  String get userProfile {
    return Intl.message(
      'User profile',
      name: 'userProfile',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get pinned {
    return Intl.message(
      'Pinned',
      name: 'pinned',
      desc: '',
      args: [],
    );
  }

  /// `Channels`
  String get channels {
    return Intl.message(
      'Channels',
      name: 'channels',
      desc: '',
      args: [],
    );
  }

  /// `Direct Messages`
  String get directMessages {
    return Intl.message(
      'Direct Messages',
      name: 'directMessages',
      desc: '',
      args: [],
    );
  }

  /// `Invite People`
  String get invitePeople {
    return Intl.message(
      'Invite People',
      name: 'invitePeople',
      desc: '',
      args: [],
    );
  }

  /// `Create Channel`
  String get createChannel {
    return Intl.message(
      'Create Channel',
      name: 'createChannel',
      desc: '',
      args: [],
    );
  }

  /// `Join Channel`
  String get joinChannel {
    return Intl.message(
      'Join Channel',
      name: 'joinChannel',
      desc: '',
      args: [],
    );
  }

  /// `Change Nickname`
  String get changeNickname {
    return Intl.message(
      'Change Nickname',
      name: 'changeNickname',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Change Avatar`
  String get changeAvatar {
    return Intl.message(
      'Change Avatar',
      name: 'changeAvatar',
      desc: '',
      args: [],
    );
  }

  /// `Leave workspace`
  String get leaveWorkspace {
    return Intl.message(
      'Leave workspace',
      name: 'leaveWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Transfer ownership`
  String get transferOwner {
    return Intl.message(
      'Transfer ownership',
      name: 'transferOwner',
      desc: '',
      args: [],
    );
  }

  /// `Delete workspace`
  String get deleteWorkspace {
    return Intl.message(
      'Delete workspace',
      name: 'deleteWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete workspace ? This action cannot be undone`
  String get descDeleteWorkspace {
    return Intl.message(
      'Are you sure want to delete workspace ? This action cannot be undone',
      name: 'descDeleteWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to leave workspace?\nThis action cannot be undone.`
  String get descLeaveWorkspace {
    return Intl.message(
      'Are you sure want to leave workspace?\nThis action cannot be undone.',
      name: 'descLeaveWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Mentions`
  String get mentions {
    return Intl.message(
      'Mentions',
      name: 'mentions',
      desc: '',
      args: [],
    );
  }

  /// `Threads`
  String get threads {
    return Intl.message(
      'Threads',
      name: 'threads',
      desc: '',
      args: [],
    );
  }

  /// `Pin this channel.`
  String get pinThisChannel {
    return Intl.message(
      'Pin this channel.',
      name: 'pinThisChannel',
      desc: '',
      args: [],
    );
  }

  /// `Unpin this channel.`
  String get unPinThisChannel {
    return Intl.message(
      'Unpin this channel.',
      name: 'unPinThisChannel',
      desc: '',
      args: [],
    );
  }

  /// `Create a workspace.`
  String get createWorkspace {
    return Intl.message(
      'Create a workspace.',
      name: 'createWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Your workspace is where you and your friends hang out. Make your and start talking.`
  String get descCreateWorkspace {
    return Intl.message(
      'Your workspace is where you and your friends hang out. Make your and start talking.',
      name: 'descCreateWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `By create a workspace, you agree to Pancake's`
  String get noteCreateWs {
    return Intl.message(
      'By create a workspace, you agree to Pancake\'s',
      name: 'noteCreateWs',
      desc: '',
      args: [],
    );
  }

  /// `Community Guidelines`
  String get communityGuide {
    return Intl.message(
      'Community Guidelines',
      name: 'communityGuide',
      desc: '',
      args: [],
    );
  }

  /// `Have an invite already?`
  String get haveAnInviteAlready {
    return Intl.message(
      'Have an invite already?',
      name: 'haveAnInviteAlready',
      desc: '',
      args: [],
    );
  }

  /// `Join a workspace`
  String get joinWorkspace {
    return Intl.message(
      'Join a workspace',
      name: 'joinWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Enter an invite below to join an existing workspace`
  String get descJoinWs {
    return Intl.message(
      'Enter an invite below to join an existing workspace',
      name: 'descJoinWs',
      desc: '',
      args: [],
    );
  }

  /// `Friends`
  String get friends {
    return Intl.message(
      'Friends',
      name: 'friends',
      desc: '',
      args: [],
    );
  }

  /// `Direct settings`
  String get directSettings {
    return Intl.message(
      'Direct settings',
      name: 'directSettings',
      desc: '',
      args: [],
    );
  }

  /// `Create group`
  String get createGroup {
    return Intl.message(
      'Create group',
      name: 'createGroup',
      desc: '',
      args: [],
    );
  }

  /// `Invite to group`
  String get inviteToGroup {
    return Intl.message(
      'Invite to group',
      name: 'inviteToGroup',
      desc: '',
      args: [],
    );
  }

  /// `Delete chat`
  String get deleteChat {
    return Intl.message(
      'Delete chat',
      name: 'deleteChat',
      desc: '',
      args: [],
    );
  }

  /// `Leave group`
  String get leaveGroup {
    return Intl.message(
      'Leave group',
      name: 'leaveGroup',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to leave this conversation?`
  String get descLeaveGroup {
    return Intl.message(
      'Are you sure want to leave this conversation?',
      name: 'descLeaveGroup',
      desc: '',
      args: [],
    );
  }

  /// `Call`
  String get call {
    return Intl.message(
      'Call',
      name: 'call',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get videoCall {
    return Intl.message(
      'Video',
      name: 'videoCall',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get accepted {
    return Intl.message(
      'Accepted',
      name: 'accepted',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Added`
  String get added {
    return Intl.message(
      'Added',
      name: 'added',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get acceptInvite {
    return Intl.message(
      'Accepted',
      name: 'acceptInvite',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Response`
  String get response {
    return Intl.message(
      'Response',
      name: 'response',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `Accept`
  String get accept {
    return Intl.message(
      'Accept',
      name: 'accept',
      desc: '',
      args: [],
    );
  }

  /// `Reject`
  String get reject {
    return Intl.message(
      'Reject',
      name: 'reject',
      desc: '',
      args: [],
    );
  }

  /// `Block`
  String get block {
    return Intl.message(
      'Block',
      name: 'block',
      desc: '',
      args: [],
    );
  }

  /// `Remove Friend`
  String get removeFriend {
    return Intl.message(
      'Remove Friend',
      name: 'removeFriend',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message(
      'Full Name',
      name: 'fullName',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message(
      'About',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Display name`
  String get displayName {
    return Intl.message(
      'Display name',
      name: 'displayName',
      desc: '',
      args: [],
    );
  }

  /// `Email address`
  String get emailAddress {
    return Intl.message(
      'Email address',
      name: 'emailAddress',
      desc: '',
      args: [],
    );
  }

  /// `Conversation name`
  String get conversationName {
    return Intl.message(
      'Conversation name',
      name: 'conversationName',
      desc: '',
      args: [],
    );
  }

  /// `Members`
  String get members {
    return Intl.message(
      'Members',
      name: 'members',
      desc: '',
      args: [],
    );
  }

  /// `Files`
  String get files {
    return Intl.message(
      'Files',
      name: 'files',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get images {
    return Intl.message(
      'Images',
      name: 'images',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: '',
      args: [],
    );
  }

  /// `Saved Messages`
  String get savedMessages {
    return Intl.message(
      'Saved Messages',
      name: 'savedMessages',
      desc: '',
      args: [],
    );
  }

  /// `Remove from saved items`
  String get removeFromSavedItems {
    return Intl.message(
      'Remove from saved items',
      name: 'removeFromSavedItems',
      desc: '',
      args: [],
    );
  }

  /// `Search ({hotkey} + F) / Anything ({hotkey} + T)`
  String searchAnything(Object hotkey) {
    return Intl.message(
      'Search ($hotkey + F) / Anything ($hotkey + T)',
      name: 'searchAnything',
      desc: '',
      args: [hotkey],
    );
  }

  /// `Search your contacts and messages in direct`
  String get desSearch {
    return Intl.message(
      'Search your contacts and messages in direct',
      name: 'desSearch',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get messages {
    return Intl.message(
      'Messages',
      name: 'messages',
      desc: '',
      args: [],
    );
  }

  /// `Contacts`
  String get contacts {
    return Intl.message(
      'Contacts',
      name: 'contacts',
      desc: '',
      args: [],
    );
  }

  /// `Or I'm looking for...`
  String get lookingFor {
    return Intl.message(
      'Or I\'m looking for...',
      name: 'lookingFor',
      desc: '',
      args: [],
    );
  }

  /// `In thread`
  String get inThread {
    return Intl.message(
      'In thread',
      name: 'inThread',
      desc: '',
      args: [],
    );
  }

  /// `Tips: Use shotkeyboard CMD + T to search anything.`
  String get tipSearch {
    return Intl.message(
      'Tips: Use shotkeyboard CMD + T to search anything.',
      name: 'tipSearch',
      desc: '',
      args: [],
    );
  }

  /// `Search all your contacts and messages.`
  String get desSearchAnything {
    return Intl.message(
      'Search all your contacts and messages.',
      name: 'desSearchAnything',
      desc: '',
      args: [],
    );
  }

  /// `Search all your directs and all workspaces`
  String get descSearchAll {
    return Intl.message(
      'Search all your directs and all workspaces',
      name: 'descSearchAll',
      desc: '',
      args: [],
    );
  }

  /// `Search all your contacts`
  String get descSearchContact {
    return Intl.message(
      'Search all your contacts',
      name: 'descSearchContact',
      desc: '',
      args: [],
    );
  }

  /// `Search your contacts and message in {name}`
  String descSearchInCtWs(Object name) {
    return Intl.message(
      'Search your contacts and message in $name',
      name: 'descSearchInCtWs',
      desc: '',
      args: [name],
    );
  }

  /// `Search messages in your direct`
  String get descSearchDms {
    return Intl.message(
      'Search messages in your direct',
      name: 'descSearchDms',
      desc: '',
      args: [],
    );
  }

  /// `Search messages in {name}`
  String descSearchInWs(Object name) {
    return Intl.message(
      'Search messages in $name',
      name: 'descSearchInWs',
      desc: '',
      args: [name],
    );
  }

  /// `Find everything for you.`
  String get findEverything {
    return Intl.message(
      'Find everything for you.',
      name: 'findEverything',
      desc: '',
      args: [],
    );
  }

  /// `Enjoy to search`
  String get enjoyToSearch {
    return Intl.message(
      'Enjoy to search',
      name: 'enjoyToSearch',
      desc: '',
      args: [],
    );
  }

  /// `Find workspace, message, contacts ...`
  String get findAll {
    return Intl.message(
      'Find workspace, message, contacts ...',
      name: 'findAll',
      desc: '',
      args: [],
    );
  }

  /// `Tip: Use shotkeyboard {hotkey}-T to search anything`
  String useShotKeyboardSearchAnything(Object hotkey) {
    return Intl.message(
      'Tip: Use shotkeyboard $hotkey-T to search anything',
      name: 'useShotKeyboardSearchAnything',
      desc: '',
      args: [hotkey],
    );
  }

  /// `Tip: Use shotkeyboard {hotkey}-T to quick search`
  String useShotKeyboardQuickSearch(Object hotkey) {
    return Intl.message(
      'Tip: Use shotkeyboard $hotkey-T to quick search',
      name: 'useShotKeyboardQuickSearch',
      desc: '',
      args: [hotkey],
    );
  }

  /// `Color Picker`
  String get colorPicker {
    return Intl.message(
      'Color Picker',
      name: 'colorPicker',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message(
      'Theme',
      name: 'theme',
      desc: '',
      args: [],
    );
  }

  /// `Auto`
  String get auto {
    return Intl.message(
      'Auto',
      name: 'auto',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get light {
    return Intl.message(
      'Light',
      name: 'light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get dark {
    return Intl.message(
      'Dark',
      name: 'dark',
      desc: '',
      args: [],
    );
  }

  /// `Languages`
  String get languages {
    return Intl.message(
      'Languages',
      name: 'languages',
      desc: '',
      args: [],
    );
  }

  /// `Your name`
  String get yourName {
    return Intl.message(
      'Your name',
      name: 'yourName',
      desc: '',
      args: [],
    );
  }

  /// `Tag name`
  String get tagName {
    return Intl.message(
      'Tag name',
      name: 'tagName',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message(
      'Email',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Phone number`
  String get phoneNumber {
    return Intl.message(
      'Phone number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Date of birth`
  String get dateOfBirth {
    return Intl.message(
      'Date of birth',
      name: 'dateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Gender`
  String get gender {
    return Intl.message(
      'Gender',
      name: 'gender',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get male {
    return Intl.message(
      'Male',
      name: 'male',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get female {
    return Intl.message(
      'Female',
      name: 'female',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message(
      'Logout',
      name: 'logout',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Online`
  String get online {
    return Intl.message(
      'Online',
      name: 'online',
      desc: '',
      args: [],
    );
  }

  /// `Offline`
  String get offline {
    return Intl.message(
      'Offline',
      name: 'offline',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get all {
    return Intl.message(
      'All',
      name: 'all',
      desc: '',
      args: [],
    );
  }

  /// `Blocked`
  String get blocked {
    return Intl.message(
      'Blocked',
      name: 'blocked',
      desc: '',
      args: [],
    );
  }

  /// `Add friend`
  String get addFriend {
    return Intl.message(
      'Add friend',
      name: 'addFriend',
      desc: '',
      args: [],
    );
  }

  /// `Enter your friend's name with their tag. Ex: JohnDoe#1234`
  String get desAddFriend {
    return Intl.message(
      'Enter your friend\'s name with their tag. Ex: JohnDoe#1234',
      name: 'desAddFriend',
      desc: '',
      args: [],
    );
  }

  /// `Enter a Username#0000`
  String get enterUsername {
    return Intl.message(
      'Enter a Username#0000',
      name: 'enterUsername',
      desc: '',
      args: [],
    );
  }

  /// `Outgoing Friend Request`
  String get outgoingFriendRequest {
    return Intl.message(
      'Outgoing Friend Request',
      name: 'outgoingFriendRequest',
      desc: '',
      args: [],
    );
  }

  /// `Incoming Friend Request`
  String get incomingFriendRequest {
    return Intl.message(
      'Incoming Friend Request',
      name: 'incomingFriendRequest',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: '',
      args: [],
    );
  }

  /// `Devices`
  String get devices {
    return Intl.message(
      'Devices',
      name: 'devices',
      desc: '',
      args: [],
    );
  }

  /// `Sync`
  String get sync {
    return Intl.message(
      'Sync',
      name: 'sync',
      desc: '',
      args: [],
    );
  }

  /// `File manager`
  String get fileManager {
    return Intl.message(
      'File manager',
      name: 'fileManager',
      desc: '',
      args: [],
    );
  }

  /// `File downloading`
  String get fileDownloading {
    return Intl.message(
      'File downloading',
      name: 'fileDownloading',
      desc: '',
      args: [],
    );
  }

  /// `Apps`
  String get apps {
    return Intl.message(
      'Apps',
      name: 'apps',
      desc: '',
      args: [],
    );
  }

  /// `Create app`
  String get createApp {
    return Intl.message(
      'Create app',
      name: 'createApp',
      desc: '',
      args: [],
    );
  }

  /// `After creating and installing the application, you can configure to stay in specific channels.`
  String get desApp {
    return Intl.message(
      'After creating and installing the application, you can configure to stay in specific channels.',
      name: 'desApp',
      desc: '',
      args: [],
    );
  }

  /// `App default`
  String get appDefault {
    return Intl.message(
      'App default',
      name: 'appDefault',
      desc: '',
      args: [],
    );
  }

  /// `Applications are available`
  String get appAvailable {
    return Intl.message(
      'Applications are available',
      name: 'appAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Synchronize messages from the left side configuration POS.`
  String get desPOSApp {
    return Intl.message(
      'Synchronize messages from the left side configuration POS.',
      name: 'desPOSApp',
      desc: '',
      args: [],
    );
  }

  /// `Notice of bank account fluctuations.`
  String get desBankApp {
    return Intl.message(
      'Notice of bank account fluctuations.',
      name: 'desBankApp',
      desc: '',
      args: [],
    );
  }

  /// `Create custom apps`
  String get customApp {
    return Intl.message(
      'Create custom apps',
      name: 'customApp',
      desc: '',
      args: [],
    );
  }

  /// `Install`
  String get install {
    return Intl.message(
      'Install',
      name: 'install',
      desc: '',
      args: [],
    );
  }

  /// `Type a message...`
  String get typeMessage {
    return Intl.message(
      'Type a message...',
      name: 'typeMessage',
      desc: '',
      args: [],
    );
  }

  /// `Pin messages`
  String get pinMessages {
    return Intl.message(
      'Pin messages',
      name: 'pinMessages',
      desc: '',
      args: [],
    );
  }

  /// `Notification setting`
  String get notifySetting {
    return Intl.message(
      'Notification setting',
      name: 'notifySetting',
      desc: '',
      args: [],
    );
  }

  /// `NORMAL MODE`
  String get normalMode {
    return Intl.message(
      'NORMAL MODE',
      name: 'normalMode',
      desc: '',
      args: [],
    );
  }

  /// `All messages have notifications and highlights.`
  String get desNormalMode {
    return Intl.message(
      'All messages have notifications and highlights.',
      name: 'desNormalMode',
      desc: '',
      args: [],
    );
  }

  /// `MENTION MODE`
  String get mentionMode {
    return Intl.message(
      'MENTION MODE',
      name: 'mentionMode',
      desc: '',
      args: [],
    );
  }

  /// `Channel dimming, highlighting and notification only when @mentions or @all.`
  String get desMentionMode {
    return Intl.message(
      'Channel dimming, highlighting and notification only when @mentions or @all.',
      name: 'desMentionMode',
      desc: '',
      args: [],
    );
  }

  /// `SILENT MODE`
  String get silentMode {
    return Intl.message(
      'SILENT MODE',
      name: 'silentMode',
      desc: '',
      args: [],
    );
  }

  /// `Turn off notifications only.`
  String get desSilentMode {
    return Intl.message(
      'Turn off notifications only.',
      name: 'desSilentMode',
      desc: '',
      args: [],
    );
  }

  /// `OFF MODE`
  String get offMode {
    return Intl.message(
      'OFF MODE',
      name: 'offMode',
      desc: '',
      args: [],
    );
  }

  /// `Nothing.`
  String get desOffMode {
    return Intl.message(
      'Nothing.',
      name: 'desOffMode',
      desc: '',
      args: [],
    );
  }

  /// `Invite`
  String get invite {
    return Intl.message(
      'Invite',
      name: 'invite',
      desc: '',
      args: [],
    );
  }

  /// `Invite to workspace`
  String get inviteToWorkspace {
    return Intl.message(
      'Invite to workspace',
      name: 'inviteToWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Invite to {name}`
  String inviteTo(Object name) {
    return Intl.message(
      'Invite to $name',
      name: 'inviteTo',
      desc: '',
      args: [name],
    );
  }

  /// `Invite existing team member or add new ones.`
  String get descInvite {
    return Intl.message(
      'Invite existing team member or add new ones.',
      name: 'descInvite',
      desc: '',
      args: [],
    );
  }

  /// `Search member`
  String get searchMember {
    return Intl.message(
      'Search member',
      name: 'searchMember',
      desc: '',
      args: [],
    );
  }

  /// `Your friends`
  String get yourFriend {
    return Intl.message(
      'Your friends',
      name: 'yourFriend',
      desc: '',
      args: [],
    );
  }

  /// `Code invite`
  String get codeInvite {
    return Intl.message(
      'Code invite',
      name: 'codeInvite',
      desc: '',
      args: [],
    );
  }

  /// `Invite new people to this channel.`
  String get inviteToChannel {
    return Intl.message(
      'Invite new people to this channel.',
      name: 'inviteToChannel',
      desc: '',
      args: [],
    );
  }

  /// `Topic`
  String get topic {
    return Intl.message(
      'Topic',
      name: 'topic',
      desc: '',
      args: [],
    );
  }

  /// `Edit channel topic`
  String get editChannelTopic {
    return Intl.message(
      'Edit channel topic',
      name: 'editChannelTopic',
      desc: '',
      args: [],
    );
  }

  /// `Edit channel description`
  String get editChannelDesc {
    return Intl.message(
      'Edit channel description',
      name: 'editChannelDesc',
      desc: '',
      args: [],
    );
  }

  /// `Set Topic`
  String get setTopic {
    return Intl.message(
      'Set Topic',
      name: 'setTopic',
      desc: '',
      args: [],
    );
  }

  /// `Set Description`
  String get setDesc {
    return Intl.message(
      'Set Description',
      name: 'setDesc',
      desc: '',
      args: [],
    );
  }

  /// `Channel name already exists`
  String get channelNameExisted {
    return Intl.message(
      'Channel name already exists',
      name: 'channelNameExisted',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to archive {name}?`
  String descArchiveChannel(Object name) {
    return Intl.message(
      'Are you sure you want to archive $name?',
      name: 'descArchiveChannel',
      desc: '',
      args: [name],
    );
  }

  /// `Create by`
  String get createBy {
    return Intl.message(
      'Create by',
      name: 'createBy',
      desc: '',
      args: [],
    );
  }

  /// `on`
  String get on {
    return Intl.message(
      'on',
      name: 'on',
      desc: '',
      args: [],
    );
  }

  /// `ago`
  String get ago {
    return Intl.message(
      'ago',
      name: 'ago',
      desc: '',
      args: [],
    );
  }

  /// `Channel Name`
  String get channelName {
    return Intl.message(
      'Channel Name',
      name: 'channelName',
      desc: '',
      args: [],
    );
  }

  /// `Channel Type`
  String get channelType {
    return Intl.message(
      'Channel Type',
      name: 'channelType',
      desc: '',
      args: [],
    );
  }

  /// `Change workflow`
  String get changeWorkflow {
    return Intl.message(
      'Change workflow',
      name: 'changeWorkflow',
      desc: '',
      args: [],
    );
  }

  /// `Archive Channel`
  String get archiveChannel {
    return Intl.message(
      'Archive Channel',
      name: 'archiveChannel',
      desc: '',
      args: [],
    );
  }

  /// `Leave Channel`
  String get leaveChannel {
    return Intl.message(
      'Leave Channel',
      name: 'leaveChannel',
      desc: '',
      args: [],
    );
  }

  /// `Delete Channel`
  String get deleteChannel {
    return Intl.message(
      'Delete Channel',
      name: 'deleteChannel',
      desc: '',
      args: [],
    );
  }

  /// `Private`
  String get private {
    return Intl.message(
      'Private',
      name: 'private',
      desc: '',
      args: [],
    );
  }

  /// `Regular`
  String get regular {
    return Intl.message(
      'Regular',
      name: 'regular',
      desc: '',
      args: [],
    );
  }

  /// `Add new apps`
  String get addNewApp {
    return Intl.message(
      'Add new apps',
      name: 'addNewApp',
      desc: '',
      args: [],
    );
  }

  /// `Connect the POS app to this channel`
  String get connectPOSApp {
    return Intl.message(
      'Connect the POS app to this channel',
      name: 'connectPOSApp',
      desc: '',
      args: [],
    );
  }

  /// `Issue`
  String get issue {
    return Intl.message(
      'Issue',
      name: 'issue',
      desc: '',
      args: [],
    );
  }

  /// `Watch`
  String get watch {
    return Intl.message(
      'Watch',
      name: 'watch',
      desc: '',
      args: [],
    );
  }

  /// `Unwatch`
  String get unwatch {
    return Intl.message(
      'Unwatch',
      name: 'unwatch',
      desc: '',
      args: [],
    );
  }

  /// `Participating and @mentions`
  String get watchMention {
    return Intl.message(
      'Participating and @mentions',
      name: 'watchMention',
      desc: '',
      args: [],
    );
  }

  /// `Only receive notifications from this channel when participating or @mentioned.`
  String get descWatchMention {
    return Intl.message(
      'Only receive notifications from this channel when participating or @mentioned.',
      name: 'descWatchMention',
      desc: '',
      args: [],
    );
  }

  /// `All Activity`
  String get watchActivity {
    return Intl.message(
      'All Activity',
      name: 'watchActivity',
      desc: '',
      args: [],
    );
  }

  /// `Notified of all notifications on this channel.`
  String get descWatchActivity {
    return Intl.message(
      'Notified of all notifications on this channel.',
      name: 'descWatchActivity',
      desc: '',
      args: [],
    );
  }

  /// `Add all comments from the subcribed issues to the thread.`
  String get watchAllComment {
    return Intl.message(
      'Add all comments from the subcribed issues to the thread.',
      name: 'watchAllComment',
      desc: '',
      args: [],
    );
  }

  /// `New issue`
  String get newIssue {
    return Intl.message(
      'New issue',
      name: 'newIssue',
      desc: '',
      args: [],
    );
  }

  /// `Labels`
  String get labels {
    return Intl.message(
      'Labels',
      name: 'labels',
      desc: '',
      args: [],
    );
  }

  /// `Milestones`
  String get milestones {
    return Intl.message(
      'Milestones',
      name: 'milestones',
      desc: '',
      args: [],
    );
  }

  /// `{count} Open`
  String open(Object count) {
    return Intl.message(
      '$count Open',
      name: 'open',
      desc: '',
      args: [count],
    );
  }

  /// `{count} Closed`
  String closed(Object count) {
    return Intl.message(
      '$count Closed',
      name: 'closed',
      desc: '',
      args: [count],
    );
  }

  /// `{count} labels`
  String countLabels(Object count) {
    return Intl.message(
      '$count labels',
      name: 'countLabels',
      desc: '',
      args: [count],
    );
  }

  /// `Name`
  String get name {
    return Intl.message(
      'Name',
      name: 'name',
      desc: '',
      args: [],
    );
  }

  /// `Add name`
  String get addName {
    return Intl.message(
      'Add name',
      name: 'addName',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get color {
    return Intl.message(
      'Color',
      name: 'color',
      desc: '',
      args: [],
    );
  }

  /// `Create label`
  String get createLabels {
    return Intl.message(
      'Create label',
      name: 'createLabels',
      desc: '',
      args: [],
    );
  }

  /// `{count} Milestones`
  String openMilestones(Object count) {
    return Intl.message(
      '$count Milestones',
      name: 'openMilestones',
      desc: '',
      args: [count],
    );
  }

  /// `Sort`
  String get sort {
    return Intl.message(
      'Sort',
      name: 'sort',
      desc: '',
      args: [],
    );
  }

  /// `Unread only`
  String get unreadOnly {
    return Intl.message(
      'Unread only',
      name: 'unreadOnly',
      desc: '',
      args: [],
    );
  }

  /// `Author`
  String get author {
    return Intl.message(
      'Author',
      name: 'author',
      desc: '',
      args: [],
    );
  }

  /// `Issues`
  String get issues {
    return Intl.message(
      'Issues',
      name: 'issues',
      desc: '',
      args: [],
    );
  }

  /// `Type or choose a name`
  String get descFileterAuthor {
    return Intl.message(
      'Type or choose a name',
      name: 'descFileterAuthor',
      desc: '',
      args: [],
    );
  }

  /// `Use ↑ ↓ ↵ to navigate`
  String get tipFilter {
    return Intl.message(
      'Use ↑ ↓ ↵ to navigate',
      name: 'tipFilter',
      desc: '',
      args: [],
    );
  }

  /// `Issues with no milestone`
  String get filterNoMilestone {
    return Intl.message(
      'Issues with no milestone',
      name: 'filterNoMilestone',
      desc: '',
      args: [],
    );
  }

  /// `Assigned to nobody`
  String get assignedNobody {
    return Intl.message(
      'Assigned to nobody',
      name: 'assignedNobody',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get sortBy {
    return Intl.message(
      'Sort by',
      name: 'sortBy',
      desc: '',
      args: [],
    );
  }

  /// `Newest`
  String get newest {
    return Intl.message(
      'Newest',
      name: 'newest',
      desc: '',
      args: [],
    );
  }

  /// `Oldest`
  String get oldest {
    return Intl.message(
      'Oldest',
      name: 'oldest',
      desc: '',
      args: [],
    );
  }

  /// `Recently Updated`
  String get recentlyUpdated {
    return Intl.message(
      'Recently Updated',
      name: 'recentlyUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Least Recently Updated`
  String get leastRecentlyUpdated {
    return Intl.message(
      'Least Recently Updated',
      name: 'leastRecentlyUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Previous`
  String get previous {
    return Intl.message(
      'Previous',
      name: 'previous',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: '',
      args: [],
    );
  }

  /// `Copy to clipboard`
  String get copyToClipboard {
    return Intl.message(
      'Copy to clipboard',
      name: 'copyToClipboard',
      desc: '',
      args: [],
    );
  }

  /// `Assignees`
  String get assignees {
    return Intl.message(
      'Assignees',
      name: 'assignees',
      desc: '',
      args: [],
    );
  }

  /// `Transfer issue`
  String get transferIssue {
    return Intl.message(
      'Transfer issue',
      name: 'transferIssue',
      desc: '',
      args: [],
    );
  }

  /// `Edit comment`
  String get editComment {
    return Intl.message(
      'Edit comment',
      name: 'editComment',
      desc: '',
      args: [],
    );
  }

  /// `Preview`
  String get preview {
    return Intl.message(
      'Preview',
      name: 'preview',
      desc: '',
      args: [],
    );
  }

  /// `Preview Comment`
  String get previewComment {
    return Intl.message(
      'Preview Comment',
      name: 'previewComment',
      desc: '',
      args: [],
    );
  }

  /// `Add a more detailed...`
  String get addDetail {
    return Intl.message(
      'Add a more detailed...',
      name: 'addDetail',
      desc: '',
      args: [],
    );
  }

  /// `Upload`
  String get upload {
    return Intl.message(
      'Upload',
      name: 'upload',
      desc: '',
      args: [],
    );
  }

  /// `Attach image to comment`
  String get attachImageToComment {
    return Intl.message(
      'Attach image to comment',
      name: 'attachImageToComment',
      desc: '',
      args: [],
    );
  }

  /// `Close issue`
  String get closeIssue {
    return Intl.message(
      'Close issue',
      name: 'closeIssue',
      desc: '',
      args: [],
    );
  }

  /// `Close with comment`
  String get closeWithComment {
    return Intl.message(
      'Close with comment',
      name: 'closeWithComment',
      desc: '',
      args: [],
    );
  }

  /// `Reopen issue`
  String get reopenIssue {
    return Intl.message(
      'Reopen issue',
      name: 'reopenIssue',
      desc: '',
      args: [],
    );
  }

  /// `Update comment`
  String get updateComment {
    return Intl.message(
      'Update comment',
      name: 'updateComment',
      desc: '',
      args: [],
    );
  }

  /// `Submit new issue`
  String get submitNewIssue {
    return Intl.message(
      'Submit new issue',
      name: 'submitNewIssue',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Add title`
  String get addTitle {
    return Intl.message(
      'Add title',
      name: 'addTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add description`
  String get addDescription {
    return Intl.message(
      'Add description',
      name: 'addDescription',
      desc: '',
      args: [],
    );
  }

  /// `Create milestone`
  String get createMilestone {
    return Intl.message(
      'Create milestone',
      name: 'createMilestone',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get saveChanges {
    return Intl.message(
      'Save changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `Due date (Opt)`
  String get dueDate {
    return Intl.message(
      'Due date (Opt)',
      name: 'dueDate',
      desc: '',
      args: [],
    );
  }

  /// `Comment`
  String get comment {
    return Intl.message(
      'Comment',
      name: 'comment',
      desc: '',
      args: [],
    );
  }

  /// `Filter labels`
  String get filterLabels {
    return Intl.message(
      'Filter labels',
      name: 'filterLabels',
      desc: '',
      args: [],
    );
  }

  /// `Filter milestones`
  String get filterMilestone {
    return Intl.message(
      'Filter milestones',
      name: 'filterMilestone',
      desc: '',
      args: [],
    );
  }

  /// `Join channel was successful.`
  String get joinChannelSuccess {
    return Intl.message(
      'Join channel was successful.',
      name: 'joinChannelSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Join the error channel. Please try again..`
  String get joinChannelFail {
    return Intl.message(
      'Join the error channel. Please try again..',
      name: 'joinChannelFail',
      desc: '',
      args: [],
    );
  }

  /// `Join workspace was successful`
  String get joinWorkspaceSuccess {
    return Intl.message(
      'Join workspace was successful',
      name: 'joinWorkspaceSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Join the error workspace. Please try again..`
  String get joinWorkspaceFail {
    return Intl.message(
      'Join the error workspace. Please try again..',
      name: 'joinWorkspaceFail',
      desc: '',
      args: [],
    );
  }

  /// `Examples`
  String get example {
    return Intl.message(
      'Examples',
      name: 'example',
      desc: '',
      args: [],
    );
  }

  /// `Workspace's name`
  String get workspaceName {
    return Intl.message(
      'Workspace\'s name',
      name: 'workspaceName',
      desc: '',
      args: [],
    );
  }

  /// `INVITE LINK OR CODE INVITE`
  String get inviteWsCode {
    return Intl.message(
      'INVITE LINK OR CODE INVITE',
      name: 'inviteWsCode',
      desc: '',
      args: [],
    );
  }

  /// `Invites should look like`
  String get inviteLookLike {
    return Intl.message(
      'Invites should look like',
      name: 'inviteLookLike',
      desc: '',
      args: [],
    );
  }

  /// `or`
  String get or {
    return Intl.message(
      'or',
      name: 'or',
      desc: '',
      args: [],
    );
  }

  /// `Or Invite by Code Workspace: `
  String get inviteCodeWs {
    return Intl.message(
      'Or Invite by Code Workspace: ',
      name: 'inviteCodeWs',
      desc: '',
      args: [],
    );
  }

  /// `Workspaces's name cannot be blank`
  String get workspaceCannotBlank {
    return Intl.message(
      'Workspaces\'s name cannot be blank',
      name: 'workspaceCannotBlank',
      desc: '',
      args: [],
    );
  }

  /// `Input cannot be empty`
  String get inputCannotEmpty {
    return Intl.message(
      'Input cannot be empty',
      name: 'inputCannotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Syntax code was wrong, try again!`
  String get syntaxError {
    return Intl.message(
      'Syntax code was wrong, try again!',
      name: 'syntaxError',
      desc: '',
      args: [],
    );
  }

  /// `More unreads`
  String get moreUnread {
    return Intl.message(
      'More unreads',
      name: 'moreUnread',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get success {
    return Intl.message(
      'Success',
      name: 'success',
      desc: '',
      args: [],
    );
  }

  /// `Issue created successfully`
  String get issueCreateSuccess {
    return Intl.message(
      'Issue created successfully',
      name: 'issueCreateSuccess',
      desc: '',
      args: [],
    );
  }

  /// `sent a video.`
  String get sentAVideo {
    return Intl.message(
      'sent a video.',
      name: 'sentAVideo',
      desc: '',
      args: [],
    );
  }

  /// `sent {count} videos.`
  String sentVideos(Object count) {
    return Intl.message(
      'sent $count videos.',
      name: 'sentVideos',
      desc: '',
      args: [count],
    );
  }

  /// `sent a file.`
  String get sentAFile {
    return Intl.message(
      'sent a file.',
      name: 'sentAFile',
      desc: '',
      args: [],
    );
  }

  /// `sent {count} files.`
  String sentFiles(Object count) {
    return Intl.message(
      'sent $count files.',
      name: 'sentFiles',
      desc: '',
      args: [count],
    );
  }

  /// `sent an image.`
  String get sentAnImage {
    return Intl.message(
      'sent an image.',
      name: 'sentAnImage',
      desc: '',
      args: [],
    );
  }

  /// `sent {count} images.`
  String sentImages(Object count) {
    return Intl.message(
      'sent $count images.',
      name: 'sentImages',
      desc: '',
      args: [count],
    );
  }

  /// `sent attachments.`
  String get sentAttachments {
    return Intl.message(
      'sent attachments.',
      name: 'sentAttachments',
      desc: '',
      args: [],
    );
  }

  /// `Attachments`
  String get attachments {
    return Intl.message(
      'Attachments',
      name: 'attachments',
      desc: '',
      args: [],
    );
  }

  /// `The video call ended.`
  String get theVideoCallEnded {
    return Intl.message(
      'The video call ended.',
      name: 'theVideoCallEnded',
      desc: '',
      args: [],
    );
  }

  /// `Logged into Google Drive`
  String get loggedIntoGoogleDrive {
    return Intl.message(
      'Logged into Google Drive',
      name: 'loggedIntoGoogleDrive',
      desc: '',
      args: [],
    );
  }

  /// `Connect Google Drive`
  String get connectGoogleDrive {
    return Intl.message(
      'Connect Google Drive',
      name: 'connectGoogleDrive',
      desc: '',
      args: [],
    );
  }

  /// `Backup`
  String get backup {
    return Intl.message(
      'Backup',
      name: 'backup',
      desc: '',
      args: [],
    );
  }

  /// `Restore`
  String get restore {
    return Intl.message(
      'Restore',
      name: 'restore',
      desc: '',
      args: [],
    );
  }

  /// `Sync by Panchat app *`
  String get syncPanchatApp {
    return Intl.message(
      'Sync by Panchat app *',
      name: 'syncPanchatApp',
      desc: '',
      args: [],
    );
  }

  /// `*Tap Sync Data and open Panchat app on your devices to get OTP code`
  String get descSyncPanchat {
    return Intl.message(
      '*Tap Sync Data and open Panchat app on your devices to get OTP code',
      name: 'descSyncPanchat',
      desc: '',
      args: [],
    );
  }

  /// `Reset device key **`
  String get resetDeviceKey {
    return Intl.message(
      'Reset device key **',
      name: 'resetDeviceKey',
      desc: '',
      args: [],
    );
  }

  /// `**Tap Reset Device Key to remove data from other devices. Panchat will send a Vertify Code to your email/phone number`
  String get descResetDeviceKey {
    return Intl.message(
      '**Tap Reset Device Key to remove data from other devices. Panchat will send a Vertify Code to your email/phone number',
      name: 'descResetDeviceKey',
      desc: '',
      args: [],
    );
  }

  /// `Please update version`
  String get pleaseUpdateVersion {
    return Intl.message(
      'Please update version',
      name: 'pleaseUpdateVersion',
      desc: '',
      args: [],
    );
  }

  /// `{statusCode} Error with status:`
  String errorWithStatus(Object statusCode) {
    return Intl.message(
      '$statusCode Error with status:',
      name: 'errorWithStatus',
      desc: '',
      args: [statusCode],
    );
  }

  /// `Mark as unread`
  String get markAsUnread {
    return Intl.message(
      'Mark as unread',
      name: 'markAsUnread',
      desc: '',
      args: [],
    );
  }

  /// `Starting up`
  String get startingUp {
    return Intl.message(
      'Starting up',
      name: 'startingUp',
      desc: '',
      args: [],
    );
  }

  /// `Nothing turned up`
  String get nothingTurnedUp {
    return Intl.message(
      'Nothing turned up',
      name: 'nothingTurnedUp',
      desc: '',
      args: [],
    );
  }

  /// `You may want to try using different keywords or checking for typos`
  String get descNothingTurnedUp {
    return Intl.message(
      'You may want to try using different keywords or checking for typos',
      name: 'descNothingTurnedUp',
      desc: '',
      args: [],
    );
  }

  /// `Type an email or phone number to invite`
  String get typeEmailOrPhoneToInvite {
    return Intl.message(
      'Type an email or phone number to invite',
      name: 'typeEmailOrPhoneToInvite',
      desc: '',
      args: [],
    );
  }

  /// `Invitation history:`
  String get invitationHistory {
    return Intl.message(
      'Invitation history:',
      name: 'invitationHistory',
      desc: '',
      args: [],
    );
  }

  /// `Sent`
  String get sent {
    return Intl.message(
      'Sent',
      name: 'sent',
      desc: '',
      args: [],
    );
  }

  /// `Please Insert KeyCode Channel`
  String get insertKeyCodeChannel {
    return Intl.message(
      'Please Insert KeyCode Channel',
      name: 'insertKeyCodeChannel',
      desc: '',
      args: [],
    );
  }

  /// `Join`
  String get join {
    return Intl.message(
      'Join',
      name: 'join',
      desc: '',
      args: [],
    );
  }

  /// `Results`
  String get results {
    return Intl.message(
      'Results',
      name: 'results',
      desc: '',
      args: [],
    );
  }

  /// `No friends to add`
  String get noFriendToAdd {
    return Intl.message(
      'No friends to add',
      name: 'noFriendToAdd',
      desc: '',
      args: [],
    );
  }

  /// `Try adding a friend using their username or email address`
  String get addFriendUsingEmail {
    return Intl.message(
      'Try adding a friend using their username or email address',
      name: 'addFriendUsingEmail',
      desc: '',
      args: [],
    );
  }

  /// `Invited`
  String get invited {
    return Intl.message(
      'Invited',
      name: 'invited',
      desc: '',
      args: [],
    );
  }

  /// `What’s up for discussion?`
  String get whatForDiscussion {
    return Intl.message(
      'What’s up for discussion?',
      name: 'whatForDiscussion',
      desc: '',
      args: [],
    );
  }

  /// `Delete member?`
  String get deleteMembers {
    return Intl.message(
      'Delete member?',
      name: 'deleteMembers',
      desc: '',
      args: [],
    );
  }

  /// `This is channel newsroom, if you remove this user from the channel it will be removed from the workspace`
  String get descDeleteNewsroom {
    return Intl.message(
      'This is channel newsroom, if you remove this user from the channel it will be removed from the workspace',
      name: 'descDeleteNewsroom',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete this member from channel?\nThis action cannot be undone.`
  String get desDeleteChannel {
    return Intl.message(
      'Are you sure want to delete this member from channel?\nThis action cannot be undone.',
      name: 'desDeleteChannel',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to leave channel?\nThis action cannot be undone.`
  String get descLeaveChannel {
    return Intl.message(
      'Are you sure want to leave channel?\nThis action cannot be undone.',
      name: 'descLeaveChannel',
      desc: '',
      args: [],
    );
  }

  /// `YOU RECEIVE AN INVITE TO JOIN A {type}`
  String receiveJoinChannel(Object type) {
    return Intl.message(
      'YOU RECEIVE AN INVITE TO JOIN A $type',
      name: 'receiveJoinChannel',
      desc: '',
      args: [type],
    );
  }

  /// `Create commands`
  String get createCommands {
    return Intl.message(
      'Create commands',
      name: 'createCommands',
      desc: '',
      args: [],
    );
  }

  /// `Shortcut:`
  String get shortcut {
    return Intl.message(
      'Shortcut:',
      name: 'shortcut',
      desc: '',
      args: [],
    );
  }

  /// `Request URL:`
  String get requestUrl {
    return Intl.message(
      'Request URL:',
      name: 'requestUrl',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Description',
      name: 'description',
      desc: '',
      args: [],
    );
  }

  /// `Params Commands:`
  String get paramsCommand {
    return Intl.message(
      'Params Commands:',
      name: 'paramsCommand',
      desc: '',
      args: [],
    );
  }

  /// `Index:`
  String get index {
    return Intl.message(
      'Index:',
      name: 'index',
      desc: '',
      args: [],
    );
  }

  /// `Params:`
  String get params {
    return Intl.message(
      'Params:',
      name: 'params',
      desc: '',
      args: [],
    );
  }

  /// `Update command`
  String get updateCommand {
    return Intl.message(
      'Update command',
      name: 'updateCommand',
      desc: '',
      args: [],
    );
  }

  /// `Create command`
  String get createCommand {
    return Intl.message(
      'Create command',
      name: 'createCommand',
      desc: '',
      args: [],
    );
  }

  /// `Edit Image`
  String get editImage {
    return Intl.message(
      'Edit Image',
      name: 'editImage',
      desc: '',
      args: [],
    );
  }

  /// `Change File`
  String get changeFile {
    return Intl.message(
      'Change File',
      name: 'changeFile',
      desc: '',
      args: [],
    );
  }

  /// `Name file: `
  String get nameFile {
    return Intl.message(
      'Name file: ',
      name: 'nameFile',
      desc: '',
      args: [],
    );
  }

  /// `Preview text`
  String get previewText {
    return Intl.message(
      'Preview text',
      name: 'previewText',
      desc: '',
      args: [],
    );
  }

  /// `Sharing this message:`
  String get shareMessage {
    return Intl.message(
      'Sharing this message:',
      name: 'shareMessage',
      desc: '',
      args: [],
    );
  }

  /// `[This message was deleted.]`
  String get thisMessageDeleted {
    return Intl.message(
      '[This message was deleted.]',
      name: 'thisMessageDeleted',
      desc: '',
      args: [],
    );
  }

  /// `commented {time}`
  String commented(Object time) {
    return Intl.message(
      'commented $time',
      name: 'commented',
      desc: '',
      args: [time],
    );
  }

  /// `•  edited by`
  String get editedBy {
    return Intl.message(
      '•  edited by',
      name: 'editedBy',
      desc: '',
      args: [],
    );
  }

  /// `•  edited`
  String get edited {
    return Intl.message(
      '•  edited',
      name: 'edited',
      desc: '',
      args: [],
    );
  }

  /// `•  edited {time}`
  String editedTime(Object time) {
    return Intl.message(
      '•  edited $time',
      name: 'editedTime',
      desc: '',
      args: [time],
    );
  }

  /// `  at {time}`
  String at(Object time) {
    return Intl.message(
      '  at $time',
      name: 'at',
      desc: '',
      args: [time],
    );
  }

  /// `Show {count} more comments`
  String showMoreComments(Object count) {
    return Intl.message(
      'Show $count more comments',
      name: 'showMoreComments',
      desc: '',
      args: [count],
    );
  }

  /// `Delete this comment?`
  String get deleteComment {
    return Intl.message(
      'Delete this comment?',
      name: 'deleteComment',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Transfer`
  String get transfer {
    return Intl.message(
      'Transfer',
      name: 'transfer',
      desc: '',
      args: [],
    );
  }

  /// `There aren't any actions for you to take on {name}.`
  String cantActionsForYou(Object name) {
    return Intl.message(
      'There aren\'t any actions for you to take on $name.',
      name: 'cantActionsForYou',
      desc: '',
      args: [name],
    );
  }

  /// `Your role cannot take action.`
  String get yourRoleCannotAction {
    return Intl.message(
      'Your role cannot take action.',
      name: 'yourRoleCannotAction',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this member?`
  String get askDeleteMember {
    return Intl.message(
      'Are you sure you want to delete this member?',
      name: 'askDeleteMember',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to leave this workspace?`
  String get askLeaveWorkspace {
    return Intl.message(
      'Are you sure you want to leave this workspace?',
      name: 'askLeaveWorkspace',
      desc: '',
      args: [],
    );
  }

  /// `Transfer to`
  String get transferTo {
    return Intl.message(
      'Transfer to',
      name: 'transferTo',
      desc: '',
      args: [],
    );
  }

  /// `Select member`
  String get selectMember {
    return Intl.message(
      'Select member',
      name: 'selectMember',
      desc: '',
      args: [],
    );
  }

  /// `Enter password to transfer`
  String get enterPassToTransfer {
    return Intl.message(
      'Enter password to transfer',
      name: 'enterPassToTransfer',
      desc: '',
      args: [],
    );
  }

  /// `Roles`
  String get roles {
    return Intl.message(
      'Roles',
      name: 'roles',
      desc: '',
      args: [],
    );
  }

  /// `Set Admin`
  String get setAdmin {
    return Intl.message(
      'Set Admin',
      name: 'setAdmin',
      desc: '',
      args: [],
    );
  }

  /// `Set Editor`
  String get setEditor {
    return Intl.message(
      'Set Editor',
      name: 'setEditor',
      desc: '',
      args: [],
    );
  }

  /// `Set Member`
  String get setMember {
    return Intl.message(
      'Set Member',
      name: 'setMember',
      desc: '',
      args: [],
    );
  }

  /// `Channel Installed`
  String get channelInstalled {
    return Intl.message(
      'Channel Installed',
      name: 'channelInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Commands`
  String get commands {
    return Intl.message(
      'Commands',
      name: 'commands',
      desc: '',
      args: [],
    );
  }

  /// `Time Created`
  String get timeCreated {
    return Intl.message(
      'Time Created',
      name: 'timeCreated',
      desc: '',
      args: [],
    );
  }

  /// `Add commands`
  String get addCommands {
    return Intl.message(
      'Add commands',
      name: 'addCommands',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message(
      'Create',
      name: 'create',
      desc: '',
      args: [],
    );
  }

  /// `Create custom app`
  String get createCustomApp {
    return Intl.message(
      'Create custom app',
      name: 'createCustomApp',
      desc: '',
      args: [],
    );
  }

  /// `App Name`
  String get appName {
    return Intl.message(
      'App Name',
      name: 'appName',
      desc: '',
      args: [],
    );
  }

  /// `Option`
  String get option {
    return Intl.message(
      'Option',
      name: 'option',
      desc: '',
      args: [],
    );
  }

  /// `Workspace`
  String get workspace {
    return Intl.message(
      'Workspace',
      name: 'workspace',
      desc: '',
      args: [],
    );
  }

  /// `Channel`
  String get channel {
    return Intl.message(
      'Channel',
      name: 'channel',
      desc: '',
      args: [],
    );
  }

  /// `Enter list title`
  String get enterListTitle {
    return Intl.message(
      'Enter list title',
      name: 'enterListTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add new list`
  String get addNewList {
    return Intl.message(
      'Add new list',
      name: 'addNewList',
      desc: '',
      args: [],
    );
  }

  /// `Add list`
  String get addList {
    return Intl.message(
      'Add list',
      name: 'addList',
      desc: '',
      args: [],
    );
  }

  /// `Create new board`
  String get createNewBoard {
    return Intl.message(
      'Create new board',
      name: 'createNewBoard',
      desc: '',
      args: [],
    );
  }

  /// `Forward this message`
  String get forwardThisMessage {
    return Intl.message(
      'Forward this message',
      name: 'forwardThisMessage',
      desc: '',
      args: [],
    );
  }

  /// `List channel`
  String get listChannel {
    return Intl.message(
      'List channel',
      name: 'listChannel',
      desc: '',
      args: [],
    );
  }

  /// `Search {type}`
  String searchType(Object type) {
    return Intl.message(
      'Search $type',
      name: 'searchType',
      desc: '',
      args: [type],
    );
  }

  /// `Forward message`
  String get forwardMessage {
    return Intl.message(
      'Forward message',
      name: 'forwardMessage',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Add new option`
  String get addNewOption {
    return Intl.message(
      'Add new option',
      name: 'addNewOption',
      desc: '',
      args: [],
    );
  }

  /// `Option: {name}`
  String optionName(Object name) {
    return Intl.message(
      'Option: $name',
      name: 'optionName',
      desc: '',
      args: [name],
    );
  }

  /// `complete`
  String get complete {
    return Intl.message(
      'complete',
      name: 'complete',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get tOpen {
    return Intl.message(
      'Open',
      name: 'tOpen',
      desc: '',
      args: [],
    );
  }

  /// `Closed`
  String get tClosed {
    return Intl.message(
      'Closed',
      name: 'tClosed',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Reopen`
  String get reopen {
    return Intl.message(
      'Reopen',
      name: 'reopen',
      desc: '',
      args: [],
    );
  }

  /// `minute`
  String get minute {
    return Intl.message(
      'minute',
      name: 'minute',
      desc: '',
      args: [],
    );
  }

  /// `minutes`
  String get minutes {
    return Intl.message(
      'minutes',
      name: 'minutes',
      desc: '',
      args: [],
    );
  }

  /// `hour`
  String get hour {
    return Intl.message(
      'hour',
      name: 'hour',
      desc: '',
      args: [],
    );
  }

  /// `hours`
  String get hours {
    return Intl.message(
      'hours',
      name: 'hours',
      desc: '',
      args: [],
    );
  }

  /// `days`
  String get days {
    return Intl.message(
      'days',
      name: 'days',
      desc: '',
      args: [],
    );
  }

  /// `day`
  String get day {
    return Intl.message(
      'day',
      name: 'day',
      desc: '',
      args: [],
    );
  }

  /// `month`
  String get month {
    return Intl.message(
      'month',
      name: 'month',
      desc: '',
      args: [],
    );
  }

  /// `months`
  String get months {
    return Intl.message(
      'months',
      name: 'months',
      desc: '',
      args: [],
    );
  }

  /// `year`
  String get year {
    return Intl.message(
      'year',
      name: 'year',
      desc: '',
      args: [],
    );
  }

  /// `years`
  String get years {
    return Intl.message(
      'years',
      name: 'years',
      desc: '',
      args: [],
    );
  }

  /// `Past due by`
  String get pastDueBy {
    return Intl.message(
      'Past due by',
      name: 'pastDueBy',
      desc: '',
      args: [],
    );
  }

  /// `Due by `
  String get dueBy {
    return Intl.message(
      'Due by ',
      name: 'dueBy',
      desc: '',
      args: [],
    );
  }

  /// `Delete Milestone`
  String get deleteMilestone {
    return Intl.message(
      'Delete Milestone',
      name: 'deleteMilestone',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete miletsone?\nThis action cannot be undone.`
  String get descDeleteMilestone {
    return Intl.message(
      'Are you sure want to delete miletsone?\nThis action cannot be undone.',
      name: 'descDeleteMilestone',
      desc: '',
      args: [],
    );
  }

  /// `Delete Label`
  String get deleteLabel {
    return Intl.message(
      'Delete Label',
      name: 'deleteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure want to delete miletsone?\nThis action cannot be undone.`
  String get descDeleteLabel {
    return Intl.message(
      'Are you sure want to delete miletsone?\nThis action cannot be undone.',
      name: 'descDeleteLabel',
      desc: '',
      args: [],
    );
  }

  /// `Please select channel`
  String get pleaseSelectChannel {
    return Intl.message(
      'Please select channel',
      name: 'pleaseSelectChannel',
      desc: '',
      args: [],
    );
  }

  /// `Select Channel`
  String get selectChannel {
    return Intl.message(
      'Select Channel',
      name: 'selectChannel',
      desc: '',
      args: [],
    );
  }

  /// `Search Channel`
  String get searchChannel {
    return Intl.message(
      'Search Channel',
      name: 'searchChannel',
      desc: '',
      args: [],
    );
  }

  /// `Recent channel`
  String get recentChannel {
    return Intl.message(
      'Recent channel',
      name: 'recentChannel',
      desc: '',
      args: [],
    );
  }

  /// `opened this issue {time}.`
  String openThisIssue(Object time) {
    return Intl.message(
      'opened this issue $time.',
      name: 'openThisIssue',
      desc: '',
      args: [time],
    );
  }

  /// `_No description provided._`
  String get noDescriptionProvided {
    return Intl.message(
      '_No description provided._',
      name: 'noDescriptionProvided',
      desc: '',
      args: [],
    );
  }

  /// `New label`
  String get newLabel {
    return Intl.message(
      'New label',
      name: 'newLabel',
      desc: '',
      args: [],
    );
  }

  /// `New milestone`
  String get newMilestone {
    return Intl.message(
      'New milestone',
      name: 'newMilestone',
      desc: '',
      args: [],
    );
  }

  /// `List Archived`
  String get listArchive {
    return Intl.message(
      'List Archived',
      name: 'listArchive',
      desc: '',
      args: [],
    );
  }

  /// `Add Params Commands`
  String get addParamsCommands {
    return Intl.message(
      'Add Params Commands',
      name: 'addParamsCommands',
      desc: '',
      args: [],
    );
  }

  /// `/ Add shortcut`
  String get addShortcut {
    return Intl.message(
      '/ Add shortcut',
      name: 'addShortcut',
      desc: '',
      args: [],
    );
  }

  /// `Add text`
  String get addText {
    return Intl.message(
      'Add text',
      name: 'addText',
      desc: '',
      args: [],
    );
  }

  /// `https:// Add url`
  String get addUrl {
    return Intl.message(
      'https:// Add url',
      name: 'addUrl',
      desc: '',
      args: [],
    );
  }

  /// `List of people in the workspace`
  String get listWorkspaceMember {
    return Intl.message(
      'List of people in the workspace',
      name: 'listWorkspaceMember',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'vi'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}

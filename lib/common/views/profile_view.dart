import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:orderit/common/services/file_converter_service.dart';
import 'package:orderit/common/services/navigation_service.dart';
import 'package:orderit/common/services/storage_service.dart';
import 'package:orderit/common/viewmodels/profile_viewmodel.dart';
import 'package:orderit/common/views/login_view.dart';
import 'package:orderit/common/widgets/abstract_factory/iwidgetsfactory.dart';
import 'package:orderit/common/widgets/common.dart';
import 'package:orderit/common/widgets/custom_toast.dart';
import 'package:orderit/config/theme.dart';
import 'package:orderit/config/theme_model.dart';
import 'package:orderit/common/models/custom_textformformfield.dart';
import 'package:orderit/locators/locator.dart';
import 'package:orderit/route/routing_constants.dart';
import 'package:orderit/common/services/camera_service.dart';
import 'package:orderit/util/constants/sizes.dart';
import 'package:orderit/util/constants/strings.dart';
import 'package:orderit/util/dio_helper.dart';
import 'package:orderit/util/display_helper.dart';
import 'package:orderit/config/styles.dart';

import 'package:orderit/util/enums.dart';
import 'package:orderit/base_view.dart';
import 'package:orderit/util/helpers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});
  static final isUserCustomer = locator.get<StorageService>().isUserCustomer;
  final _formKey = GlobalKey<FormState>(debugLabel: 'profile');
  @override
  Widget build(BuildContext context) {
    return BaseView<ProfileViewModel>(
      onModelReady: (model) async {
        await model.getUser();
        model.initData();
        model.parseDateTime();
      },
      builder: (context, model, child) {
        return Scaffold(
          appBar: Common.commonAppBar('Profile', [], context),
          body: model.state == ViewState.busy
              ? WidgetsFactoryList.circularProgressIndicator()
              : Consumer(builder: (context, ThemeModel themeModel, child) {
                  var isDark = themeModel.isDark;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return smallScreen(
                          model, context, themeModel, themeModel.isDark);
                    },
                  );
                }),
        );
      },
    );
  }

  Widget smallScreen(ProfileViewModel model, BuildContext context,
      ThemeModel themeNotifier, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: Sizes.smallPaddingWidget(context),
        right: Sizes.smallPaddingWidget(context),
        top: Sizes.paddingWidget(context),
        bottom: Sizes.smallPaddingWidget(context),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            UserImage(model: model),
            SizedBox(height: Sizes.paddingWidget(context)),
            fullNameField(model, context),
            SizedBox(height: Sizes.paddingWidget(context)),
            emailAddressField(model, context),
            SizedBox(height: Sizes.paddingWidget(context)),
            mobileNoField(model, context),
            SizedBox(height: Sizes.paddingWidget(context)),
            connectedToUrlField(model, context),
            SizedBox(height: Sizes.paddingWidget(context)),
            SizedBox(
              width: displayWidth(context) < 600
                  ? displayWidth(context)
                  : displayWidth(context) * 0.5,
              height: Sizes.buttonHeightWidget(context),
              child: ElevatedButton(
                onPressed: () async {
                  await model.logout(context);
                },
                child: Text('Logout',
                    style: TextStyle(
                        fontSize: Sizes.fontSizeTextButtonWidget(context))),
              ),
            ),
            const Spacer(),
            const PoweredByAmbibuzzLogo(),
            Padding(
              padding: EdgeInsets.only(
                  bottom: defaultTargetPlatform == TargetPlatform.iOS
                      ? Sizes.smallPaddingWidget(context)
                      : 0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'v${model.version}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget switchTheme(ThemeModel themeNotifier, BuildContext context) {
    var isDark = themeNotifier.isDark;
    return Row(
      children: [
        Text(
          isDark ? 'Dark Theme' : 'Light Theme',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Switch(
          value: isDark,
          onChanged: (bool val) {
            themeNotifier.isDark = val;
          },
        ),
      ],
    );
  }

  Widget emailAddressField(ProfileViewModel model, BuildContext context) {
    return CustomTextFormField(
      key: const Key('email_address_field'),
      controller: model.emailController,
      decoration: Common.inputDecoration(),
      label: 'Email',
      readOnly: true,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget mobileNoField(ProfileViewModel model, BuildContext context) {
    return CustomTextFormField(
      key: const Key('mobile_no_field'),
      controller: model.mobileNoController,
      decoration: Common.inputDecoration(),
      label: 'Mobile No',
      style: Theme.of(context).textTheme.bodyMedium,
      validator: (val) =>
          val == '' || val == null ? 'Mobile number should not be empty' : null,
    );
  }

  Widget fullNameField(ProfileViewModel model, BuildContext context) {
    return CustomTextFormField(
      key: const Key('full_name_field'),
      controller: model.fullNameController,
      decoration: Common.inputDecoration(),
      label: 'Full Name',
      style: Theme.of(context).textTheme.bodyMedium,
      readOnly: true,
    );
  }

  Widget connectedToUrlField(ProfileViewModel model, BuildContext context) {
    return CustomTextFormField(
      initialValue: locator.get<StorageService>().apiUrl,
      decoration: Common.inputDecoration().copyWith(
          prefixIcon: Icon(
        Icons.cast_connected,
        color: CustomTheme.iconColor,
      )),
      label: 'Connected To',
      style: Theme.of(context).textTheme.bodyMedium,
      readOnly: true,
    );
  }
}

class MoreInfo extends StatelessWidget {
  final List<Widget>? widgets;
  const MoreInfo({super.key, this.widgets});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.mediumPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widgets ?? [],
      ),
    );
  }
}

class SubHeading extends StatelessWidget {
  final String? title;
  final String? text;
  const SubHeading({super.key, this.title, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: Sizes.smallPadding,
          horizontal: displayWidth(context) * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? '',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: Sizes.smallPadding),
          SizedBox(
            width: displayWidth(context) * 0.35,
            height: displayHeight(context) * 0.07,
            child: TextFormField(
              controller: TextEditingController(text: text),
              decoration: InputDecoration(
                fillColor: const Color(0xFFE7E5E5),
                filled: true,
                isDense: true,
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: Corners.xxlBorder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubheadingWidget extends StatelessWidget {
  final String? title;
  final String? text;
  const SubheadingWidget({super.key, this.title, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.smallPadding),
      child: Row(
        children: [
          Text(
            title ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          Text(text ?? ''),
        ],
      ),
    );
  }
}

class Heading extends StatelessWidget {
  final ProfileViewModel model;
  const Heading({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.padding),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.user.fullName ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                model.user.username ?? '',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
          const Spacer(),
          UserImage(model: model),
        ],
      ),
    );
  }
}

class UserImage extends StatelessWidget {
  final ProfileViewModel model;
  const UserImage({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    var imageDimension = displayWidth(context) < 600 ? 140.0 : 240.0;
    String finalFilePath;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Pick Image',
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              height: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final picker = ImagePicker();
                      // Capture a photo.
                      var image = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 30);
                      model.setImage(image);
                      if (image != null) {
                        var img64 =
                            FileConverter.getBase64FormateFile(image.path);
                        // upload image
                        await locator
                            .get<CameraService>()
                            .uploadImage(context, img64, File(image.path), 0,
                                'User', model.user.email)
                            .then(
                              (value) => {
                                if (value['message']['file_url'] != null)
                                  {finalFilePath = value['message']['file_url']}
                                else
                                  {finalFilePath = ''},
                                if (finalFilePath != '')
                                  {
                                    // upload image to user doctype
                                    model
                                        .updateUserImage(finalFilePath)
                                        .then((value) async {
                                      // refetch update user
                                      await model.refetchUpdatedUser();
                                    })
                                  }
                                else
                                  {
                                    Future.delayed(const Duration(seconds: 2),
                                        () async {}),
                                    flutterSimpleToast(Colors.white,
                                        Colors.black, 'Couldnt Upload Image')
                                  }
                              },
                            );
                      }
                    },
                    child: const Text('Gallery'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final picker = ImagePicker();
                      // Pick an image.
                      final image = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 30);
                      model.setImage(image);
                      if (image != null) {
                        var img64 =
                            FileConverter.getBase64FormateFile(image.path);
                        // upload image
                        await locator
                            .get<CameraService>()
                            .uploadImage(context, img64, File(image.path), 0,
                                'User', model.user.email)
                            .then(
                              (value) => {
                                if (value['message']['file_url'] != null)
                                  {finalFilePath = value['message']['file_url']}
                                else
                                  {finalFilePath = ''},
                                if (finalFilePath != '')
                                  {
                                    // upload image to user doctype
                                    model
                                        .updateUserImage(finalFilePath)
                                        .then((value) async {
                                      // refetch update user
                                      await model.refetchUpdatedUser();
                                    })
                                  }
                                else
                                  {
                                    Future.delayed(const Duration(seconds: 2),
                                        () async {
                                      await locator
                                          .get<NavigationService>()
                                          .pushNamedAndRemoveUntil(
                                              enterCustomerRoute, (_) => false);
                                    }),
                                    flutterSimpleToast(Colors.white,
                                        Colors.black, 'Couldnt Upload Image')
                                  }
                              },
                            );
                      }
                    },
                    child: const Text('Camera'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: model.user.userImage != null
          ? ClipOval(
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl:
                    '${locator.get<StorageService>().apiUrl}${model.user.userImage}',
                httpHeaders: {
                  HttpHeaders.cookieHeader: DioHelper.cookies ?? ''
                },
                width: imageDimension,
                height: imageDimension,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(Icons.error),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            )
          : Container(
              width: imageDimension,
              height: imageDimension,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColorLight,
              ),
              child: Center(
                child: Text(
                  model.user.firstName != null
                      ? model.user.firstName![0] ?? ''
                      : '',
                  style: displayWidth(context) < 600
                      ? Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600)
                      : Theme.of(context).textTheme.headlineLarge!.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600),
                ),
              ),
            ),
    );
  }
}

class LogoutTile extends StatelessWidget {
  final ProfileViewModel? model;
  const LogoutTile({super.key, this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sizes.padding),
      width: displayWidth(context),
      height: 70,
      child: TextButton(
        key: const Key(TestCasesConstants.logoutButton),
        onPressed: () async {
          await model?.logout(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: ThemeModel().isDark ? Colors.black : Colors.white),
            ),
            const SizedBox(
              width: 10,
            ),
            const Icon(
              Icons.logout,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

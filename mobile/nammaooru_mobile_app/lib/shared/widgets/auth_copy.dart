import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';

String authCopy(BuildContext context, String english) {
  const tamil = {
    'Login': 'உள்நுழைய',
    'Register': 'பதிவு செய்ய',
    'Create account': 'கணக்கை உருவாக்க',
    'Sign in to your account': 'உங்கள் கணக்கில் உள்நுழையுங்கள்',
    'Enter your details to get started': 'தொடங்க உங்கள் விவரங்களை உள்ளிடுங்கள்',
    'Full Name': 'முழுப் பெயர்',
    'Email': 'மின்னஞ்சல்',
    'Phone Number': 'கைபேசி எண்',
    'Mobile Number': 'கைபேசி எண்',
    'Enter your password': 'கடவுச்சொல்',
    'Password (min 4 characters)': 'கடவுச்சொல் (குறைந்தது 4 எழுத்துகள்)',
    'Remember me': 'நினைவில் கொள்க',
    'Forgot Password?': 'கடவுச்சொல் மறந்ததா?',
    'I agree to ': 'ஒப்புக்கொள்கிறேன்: ',
    'Terms & Privacy Policy': 'விதிமுறைகள் & தனியுரிமைக் கொள்கை',
    'Already have an account?': 'ஏற்கனவே கணக்கு உள்ளதா?',
    'Registering...': 'பதிவு செய்யப்படுகிறது...',
    'Please enter your name': 'உங்கள் பெயரை உள்ளிடுங்கள்',
    'Name must be at least 2 characters': 'பெயரில் குறைந்தது 2 எழுத்துகள் தேவை',
    'Please enter your email': 'மின்னஞ்சலை உள்ளிடுங்கள்',
    'Please enter a valid email': 'சரியான மின்னஞ்சலை உள்ளிடுங்கள்',
    'Please enter your phone number': 'கைபேசி எண்ணை உள்ளிடுங்கள்',
    'Please enter your mobile number': 'கைபேசி எண்ணை உள்ளிடுங்கள்',
    'Enter a valid 10-digit phone number': 'சரியான 10 இலக்க எண்ணை உள்ளிடுங்கள்',
    'Mobile number must be 10 digits': 'கைபேசி எண்ணில் 10 இலக்கங்கள் தேவை',
    'Please enter a password': 'கடவுச்சொல்லை உள்ளிடுங்கள்',
    'Please enter your password': 'கடவுச்சொல்லை உள்ளிடுங்கள்',
    'Password must be at least 4 characters': 'கடவுச்சொல்லில் குறைந்தது 4 எழுத்துகள் தேவை',
  };
  return Provider.of<LanguageProvider>(context, listen: false)
      .getText(english, tamil[english] ?? english);
}

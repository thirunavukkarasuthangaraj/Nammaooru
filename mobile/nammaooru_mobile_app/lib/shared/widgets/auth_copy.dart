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

    // Phone-first auth wizard
    'Welcome to NammaOoru': 'நம்ம ஊருவிற்கு வரவேற்கிறோம்',
    'Enter your mobile number to continue': 'தொடர உங்கள் கைபேசி எண்ணை உள்ளிடவும்',
    'Sign in with your phone': 'உங்கள் கைபேசி மூலம் உள்நுழையவும்',
    "No password to remember — we'll text you a code to verify it's you.":
        'கடவுச்சொல் தேவையில்லை — நீங்கள்தான் என உறுதிப்படுத்த ஒரு குறியீட்டை அனுப்புவோம்.',
    'Send OTP': 'OTP அனுப்பவும்',
    "What's your name?": 'உங்கள் பெயர் என்ன?',
    'Mobile number verified': 'கைபேசி எண் சரிபார்க்கப்பட்டது',
    'Next': 'அடுத்து',
    'Almost there!': 'கிட்டத்தட்ட முடிந்தது!',
    "Add your email if you'd like (optional)": 'விரும்பினால் உங்கள் மின்னஞ்சலைச் சேர்க்கவும் (விருப்பம்)',
    'Email (optional)': 'மின்னஞ்சல் (விருப்பம்)',
    'Create Account': 'கணக்கை உருவாக்கவும்',
    'Skip for now': 'இப்போதைக்கு தவிர்க்கவும்',
    'Continue with phone number instead': 'கைபேசி எண் மூலம் தொடரவும்',

    // OTP verification screen
    'Verify your number': 'உங்கள் எண்ணை சரிபார்க்கவும்',
    'We sent a 6-digit code to': 'ஒரு 6 இலக்க குறியீட்டை அனுப்பியுள்ளோம்',
    'Verifying OTP...': 'OTP சரிபார்க்கப்படுகிறது...',
    'Please enter OTP': 'OTP-ஐ உள்ளிடவும்',
    'OTP must be 6 digits': 'OTP 6 இலக்கங்களாக இருக்க வேண்டும்',
    'Code expires in': 'குறியீடு காலாவதியாகும் நேரம்',
    'Verify OTP': 'OTP சரிபார்க்கவும்',
    'Resend Code': 'மீண்டும் அனுப்பவும்',
    'Resend in': 'மீண்டும் அனுப்ப',
    'Change Mobile number': 'கைபேசி எண்ணை மாற்றவும்',
  };
  return Provider.of<LanguageProvider>(context, listen: false)
      .getText(english, tamil[english] ?? english);
}


class URLS {
  static const String baseUrl = 'https://api.gocarriage.com/api';
  static const String imagBaseUrlOwner = 'https://zebraffeebucket2026.s3.ap-south-1.amazonaws.com/owners/';
  static const String bookingBaseUrl = 'https://booking.api.gocarriage.com';
  static const String clusterBaseUrl = 'https://management.api.gocarriage.com/api';
  static const String fileUpload = 'https://api.gocarriage.com/api/upload';
  static const String imageUrlGet = 'https://api.gocarriage.com/api/upload/signed-url?key=';
  static const String versionControl = '$baseUrl/app-version/check?platform=android&build=';

  //////////////////////Corporate Dashboard Api /////////////////////
  static const String normalCustomerDashboard = '$bookingBaseUrl/booking/dashboard';
  static const String normalCustomerBookingActivity = '$bookingBaseUrl/booking/activity?limit=';
  static const String normalCustomerWalletBalance = '$bookingBaseUrl/wallet/balance';
  static const String normalCustomerTransactionLimit = '$bookingBaseUrl/wallet/transactions?limit=';
  static const String normalCustomerOfferMe = '$baseUrl/offers/me';
  static const String normalCustomerCorporateOverview = '$bookingBaseUrl/corporate/overview';
  static const String normalCustomerCorporateMe = '$baseUrl/corporate/me';
  static const String normalCustomerCorporate = '$bookingBaseUrl/corporate';

  ////////////////////////Freight Calculator////////////////////////
 static const String freightVehicleModels ='$baseUrl/freight/owner/models';
 static const String freightVehicle ='$baseUrl/freight/owner/vehicle';
 static const String freightFleetModel ='$baseUrl/freight/fleet/model-freight?vehicle_model_id=';
 static const String freightEmiDefault ='https://management.api.gocarriage.com/api/freight/meta/emi-defaults';
 static const String freightEmiPreview ='https://management.api.gocarriage.com/api/freight/emi/preview';
 static const String vehicleModelClass ='$baseUrl/vehicle-models/classes';


  static const String login = '$baseUrl/auth/login';
  static const String sendOtp = '$baseUrl/phone-otp/send-registration';
  static const String verifyOtp = '$baseUrl/phone-otp/verify-registration';
  
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String registerCustomer = '$baseUrl/customers/create';
  static const String bookingAllRide = '${bookingBaseUrl}/booking/history';
  static const String rescheduleApi = '${baseUrl}/bookings/reschedule';
  static const String nearByVehicle = '${bookingBaseUrl}/booking/nearby-vehicle-types';
  static const String fareCalculate = '${baseUrl}/bookings/vehicle-types/priced';

  static const String fetchProfileCustomer = '$baseUrl/customers/';
  static const String clustersPinCheck = '$clusterBaseUrl/clusters/check-pincode?pincode=';
  static const String clustersCheckSame = '$clusterBaseUrl/clusters/check-same';
  static const String bookingTrip = '$bookingBaseUrl/booking';
  static const String customerBooking = '$bookingBaseUrl/booking/';

  static const String privacyPolicy = '${baseUrl}/privacy-policy';
  static const String termsCondition = '${baseUrl}/terms-condition';
  static const String Faq = '${baseUrl}get-faq';
  static const String aboutUs = '${baseUrl}get-about-us';
  static const String HelpSupport = '${baseUrl}help-support';
  static const String updateProfile = '${baseUrl}update-profile';
  static const String deleteProfile = '${baseUrl}delete-profile';


  /////////////Owners/////////////////////
  static const String registerOwners = '$baseUrl/owners/create';
  static const String profileOwners = '$baseUrl/owners/';
  static const String listFleetsByOwner = '$baseUrl/fleets/by-owner';
  static const String vehicleDetails = '$baseUrl/fleets/get-by-id/';
  static const String listDriverByOwner = '$baseUrl/owners/get-added-drivers';
  static const String assignDriverByOwner = '$baseUrl/owners/driver-vehicle-assignments/by-owner';
  static const String assignDriver = '$baseUrl/owners/assign-driver';
  static const String assignDriverVehicle = '$baseUrl/owners/assign-driver-vehicle';
  static const String unAssignVehicle = '$baseUrl/owners/unassign-driver-vehicle';
  static const String unAssignDriver = '$baseUrl/owners/unassign-driver-owner';
  static const String addVehicle = '$baseUrl/fleets';
  static const String vehicleDocumentsBulk = '$baseUrl/vehicle-documents/bulk';
  static const String vehicleTypes = '$baseUrl/vehicle-types';
  static const String vehicleBrand = '$baseUrl/vehicle-models/brands';
  static const String vehicleCategoryBy = '$baseUrl/vehicle-models/by-category/';
  static const String subscriptions = '$baseUrl/fleet-subscriptions/fleet/';
  static const String uploadVehicleDocumentsBulk = '$baseUrl/vehicle-documents/bulk/';
  static const String transactionHistory = '$baseUrl/credit-wallets/fleet/';
  static const String vehicleModel = '$baseUrl/vehicle-models/by-brand/';
  static const String searchDriverByPhone = '$baseUrl/drivers/by-phone';
  static const String requestOwner = '$baseUrl/owners/get-request-owner';
  static const String requestAcceptOwner = '$baseUrl/owners/request-update/';
  static const String bookingRequestListOwner = '$baseUrl/owners/me/bookings';
  static const String quatationsService = '$baseUrl/owners/me/quotations';
  static const String draftVehicle = '$baseUrl/fleets/get-by-id/';
  static const String subscriptionsList = '$baseUrl/fleets/owner-summary/';
  static const String rewardsWallet = '$baseUrl/rewards/me';
  static const String freightFleetCostsUpload = '$baseUrl/freight/fleet/';
  static const String tenderBooking = '$bookingBaseUrl/booking/tenders';
  static const String fleetVehicleList = '$bookingBaseUrl/booking/owners/me/available-fleets?vehicle_type_id=';
  static const String negotiationsBookingList = '$bookingBaseUrl/booking/negotiations?scope=won';
  static const String negotiationsOpenBookingList = '$bookingBaseUrl/booking/negotiations?scope=open';
  static const String instantTripList = '$bookingBaseUrl/booking/instant-requests';

  /////////////Driver/////////////////////
  static const String registerDriver = '$baseUrl/drivers/register';
  static const String fetchProfileDriver = '$baseUrl/drivers/';
  static const String driverBooking = '$bookingBaseUrl/driver/booking/';
  static const String bookingAccept = '$bookingBaseUrl/driver/booking/accept';
  static const String bookingReject = '$bookingBaseUrl/driver/booking/reject';
  static const String onlineDriver = '$bookingBaseUrl/driver/online';
  static const String offlineDriver = '$bookingBaseUrl/driver/offline';
  static const String startTrip = '$bookingBaseUrl/driver/trip/update-status';
  static const String completeTrip = '$baseUrl/driver/trip/complete';
  static const String driverArrived = '$baseUrl/driver/trip/arrived';
  static const String driverBookingHistory = '$bookingBaseUrl/driver/booking/upcoming';
  static const String driverBookingHistoryFull = '$bookingBaseUrl/driver/booking/history';
  static const String driverOngoingHistory = '$bookingBaseUrl/driver/booking/accepted';
  static const String driverOtpVerify = '$bookingBaseUrl/driver/booking/validate-otp';
  static const String driverEmailOtp = '$baseUrl/email/send-email-otp';
  static const String driverEmailVerifyOtp = '$baseUrl/email/verify-email-otp';
  static const String placeApi = 'https://dev.happiesttravel.com/api/users/searchlocation';


  ////////////////////////////Operator////////////////////////////////////
  static const String registerOperator ='$baseUrl/operator';
  static const String operatorVehicleRequestList ='$baseUrl/operator/get-vehicle-requests';
  static const String operatorBookingList ='$baseUrl/bookings?';
  static const String searchRegistrationNumber ='$baseUrl/fleets/search?registration_number=';
  static const String operatorPermission ='$baseUrl/operator-permissions';
  static const String operatorVehicleRequest ='$baseUrl/operator/vehicle-request';


}
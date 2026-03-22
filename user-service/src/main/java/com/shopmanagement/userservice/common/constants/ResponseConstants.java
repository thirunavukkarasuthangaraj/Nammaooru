package com.shopmanagement.userservice.common.constants;

public class ResponseConstants {

    public static final String SUCCESS = "0000";
    public static final String SUCCESS_MESSAGE = "Success";

    public static final String GENERAL_ERROR = "9999";
    public static final String UNAUTHORIZED = "1001";
    public static final String UNAUTHORIZED_MESSAGE = "Unauthorized access";
    public static final String FORBIDDEN = "1002";
    public static final String FORBIDDEN_MESSAGE = "Access forbidden";
    public static final String VALIDATION_ERROR = "2001";
    public static final String REQUIRED_FIELD_MISSING = "2002";
    public static final String USER_NOT_FOUND = "3002";
    public static final String INTERNAL_SERVER_ERROR = "7001";
    public static final String INTERNAL_SERVER_ERROR_MESSAGE = "Internal server error";

    private ResponseConstants() {}
}

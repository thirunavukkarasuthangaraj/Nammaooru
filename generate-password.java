import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class GeneratePassword {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String rawPassword = "password123";
        String encodedPassword = encoder.encode(rawPassword);
        System.out.println("Raw: " + rawPassword);
        System.out.println("Encoded: " + encodedPassword);
        System.out.println("\nSQL Update:");
        System.out.println("UPDATE users SET password = '" + encodedPassword + "' WHERE role IN ('SUPER_ADMIN', 'ADMIN', 'SHOP_OWNER', 'CUSTOMER', 'DELIVERY_PARTNER');");
    }
}
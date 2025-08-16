import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class TestPassword {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String password = "admin123";
        String hash = encoder.encode(password);
        System.out.println("Generated hash for '" + password + "': " + hash);
        
        // Test the existing hash
        String existingHash = "$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy";
        boolean matches = encoder.matches(password, existingHash);
        System.out.println("Password 'admin123' matches existing hash: " + matches);
    }
}
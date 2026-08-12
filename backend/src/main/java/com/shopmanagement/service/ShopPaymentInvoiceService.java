package com.shopmanagement.service;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.shopmanagement.entity.ShopPaymentCollection;
import com.shopmanagement.shop.entity.Shop;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.format.DateTimeFormatter;

/**
 * Sends the pay-and-use payment receipt to the shop owner over email and
 * WhatsApp, reusing the existing bill infrastructure: EmailService.sendBillEmail
 * and the approved bill_receipt WhatsApp template (document header).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ShopPaymentInvoiceService {

    private final EmailService emailService;
    private final WhatsAppNotificationService whatsAppNotificationService;

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    @Value("${app.api.base-url:https://api.nammaoorudelivary.in}")
    private String apiBaseUrl;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd MMM yyyy, hh:mm a");

    /**
     * Fire-and-forget: a receipt failure must never fail or slow the payment itself.
     */
    @Async
    public void sendPaymentReceipt(Shop shop, ShopPaymentCollection payment) {
        String invoiceNo = "PAY-" + payment.getId();
        try {
            byte[] pdfBytes = buildReceiptPdf(shop, payment, invoiceNo);
            String amount = String.valueOf(payment.getAmount());

            // Email (owner email can be blank for some shops)
            String email = shop.getOwnerEmail();
            if (email != null && !email.isBlank() && !email.endsWith("@pos.local")) {
                try {
                    emailService.sendBillEmail(email, shop.getOwnerName(), "NammaOoru",
                            invoiceNo, amount, pdfBytes, invoiceNo + ".pdf");
                } catch (Exception e) {
                    log.error("Payment receipt email failed for shop {}: {}", shop.getId(), e.getMessage());
                }
            }

            // WhatsApp via the approved bill_receipt template (needs a hosted PDF URL)
            String phone = shop.getOwnerPhone();
            if (phone != null && !phone.isBlank()) {
                try {
                    Path billsDir = Paths.get(uploadDir, "bills");
                    Files.createDirectories(billsDir);
                    String fileName = "receipt_" + invoiceNo + "_" + payment.getRazorpayOrderId() + ".pdf";
                    Files.write(billsDir.resolve(fileName), pdfBytes);
                    String pdfUrl = apiBaseUrl + "/uploads/bills/" + fileName;

                    whatsAppNotificationService.sendBillDocument(phone, shop.getOwnerName(),
                            "NammaOoru", invoiceNo, amount, pdfUrl, invoiceNo + ".pdf");
                } catch (Exception e) {
                    log.error("Payment receipt WhatsApp failed for shop {}: {}", shop.getId(), e.getMessage());
                }
            }

            log.info("Payment receipt {} dispatched for shop {} (email: {}, phone: {})",
                    invoiceNo, shop.getId(), email != null && !email.isBlank(), phone != null && !phone.isBlank());
        } catch (Exception e) {
            log.error("Failed to build/send payment receipt for shop {}", shop.getId(), e);
        }
    }

    private byte[] buildReceiptPdf(Shop shop, ShopPaymentCollection payment, String invoiceNo) throws Exception {
        Document document = new Document(PageSize.A5, 36, 36, 36, 36);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, out);
        document.open();

        Color green = new Color(46, 125, 50);
        Font title = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, green);
        Font label = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.DARK_GRAY);
        Font value = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.BLACK);
        Font big = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, green);

        Paragraph header = new Paragraph("NammaOoru - Payment Receipt", title);
        header.setAlignment(Element.ALIGN_CENTER);
        header.setSpacingAfter(14f);
        document.add(header);

        PdfPTable table = new PdfPTable(new float[]{1.2f, 2f});
        table.setWidthPercentage(100);
        addRow(table, "Receipt No", invoiceNo, label, value);
        addRow(table, "Shop", shop.getName(), label, value);
        addRow(table, "Owner", shop.getOwnerName(), label, value);
        addRow(table, "Paid on", payment.getPaidAt() != null ? payment.getPaidAt().format(DATE_FMT) : "-", label, value);
        addRow(table, "Payment ID", payment.getRazorpayPaymentId(), label, value);
        addRow(table, "Access valid until", payment.getValidUntil() != null ? payment.getValidUntil().format(DATE_FMT) : "-", label, value);
        document.add(table);

        Paragraph amount = new Paragraph("Amount Paid: Rs. " + payment.getAmount(), big);
        amount.setAlignment(Element.ALIGN_CENTER);
        amount.setSpacingBefore(16f);
        amount.setSpacingAfter(10f);
        document.add(amount);

        Paragraph thanks = new Paragraph("Thank you for using NammaOoru. Your shop stays live for the full paid period.", label);
        thanks.setAlignment(Element.ALIGN_CENTER);
        document.add(thanks);

        document.close();
        return out.toByteArray();
    }

    private void addRow(PdfPTable table, String labelText, String valueText, Font labelFont, Font valueFont) {
        PdfPCell l = new PdfPCell(new Phrase(labelText, labelFont));
        l.setBorder(Rectangle.NO_BORDER);
        l.setPadding(5f);
        table.addCell(l);
        PdfPCell v = new PdfPCell(new Phrase(valueText != null ? valueText : "-", valueFont));
        v.setBorder(Rectangle.NO_BORDER);
        v.setPadding(5f);
        table.addCell(v);
    }
}

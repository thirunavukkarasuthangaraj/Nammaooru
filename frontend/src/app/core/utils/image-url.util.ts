import { environment } from '../../../environments/environment';

/**
 * Centralized utility function to get full image URL
 * This ensures consistent image URL handling across the entire application
 */
export function getImageUrl(imagePath: string | null | undefined): string {
  if (!imagePath || imagePath === '') {
    return '';
  }

  // If it's already a full URL, return as is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }

  // Remove /api/ prefix if present (for backward compatibility with old data)
  let cleanPath = imagePath;
  if (cleanPath.startsWith('/api/')) {
    cleanPath = cleanPath.substring(4); // Remove '/api' prefix
  }

  // Ensure path starts with /
  if (!cleanPath.startsWith('/')) {
    cleanPath = '/' + cleanPath;
  }

  // Construct full URL with imageBaseUrl
  return `${environment.imageBaseUrl}${cleanPath}`;
}

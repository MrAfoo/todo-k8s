/**
 * Text utility functions for processing messages
 */

/**
 * Removes emojis, icons, and special symbols from text for better text-to-speech output
 * @param text - The text to clean
 * @returns Cleaned text without emojis/icons
 */
export function stripEmojisAndIcons(text: string): string {
  if (!text) return '';

  return text
    // Remove emojis (covers most emoji ranges)
    .replace(/[\u{1F600}-\u{1F64F}]/gu, '') // Emoticons
    .replace(/[\u{1F300}-\u{1F5FF}]/gu, '') // Misc Symbols and Pictographs
    .replace(/[\u{1F680}-\u{1F6FF}]/gu, '') // Transport and Map
    .replace(/[\u{1F1E0}-\u{1F1FF}]/gu, '') // Flags
    .replace(/[\u{2600}-\u{26FF}]/gu, '')   // Misc symbols (including ⚡, ✓, etc.)
    .replace(/[\u{2700}-\u{27BF}]/gu, '')   // Dingbats
    .replace(/[\u{1F900}-\u{1F9FF}]/gu, '') // Supplemental Symbols and Pictographs
    .replace(/[\u{1FA00}-\u{1FA6F}]/gu, '') // Chess Symbols
    .replace(/[\u{1FA70}-\u{1FAFF}]/gu, '') // Symbols and Pictographs Extended-A
    .replace(/[\u{FE00}-\u{FE0F}]/gu, '')   // Variation Selectors
    .replace(/[\u{200D}]/gu, '')            // Zero Width Joiner (used in combined emojis)
    
    // Remove common special symbols used in UI
    .replace(/[✓✗✕✖✔✘]/g, '')              // Checkmarks and crosses
    .replace(/[➜➤➔→←↑↓]/g, '')              // Arrows
    .replace(/[★☆⭐]/g, '')                  // Stars
    .replace(/[♠♣♥♦]/g, '')                  // Card suits
    .replace(/[■□▪▫]/g, '')                  // Boxes
    .replace(/[●○◆◇]/g, '')                  // Circles and diamonds
    
    // Clean up multiple spaces and trim
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Cleans markdown formatting for better text-to-speech
 * @param text - The text with markdown
 * @returns Text without markdown formatting
 */
export function stripMarkdown(text: string): string {
  if (!text) return '';

  return text
    // Remove bold/italic markers
    .replace(/\*\*\*(.+?)\*\*\*/g, '$1')    // Bold + Italic
    .replace(/\*\*(.+?)\*\*/g, '$1')         // Bold
    .replace(/\*(.+?)\*/g, '$1')             // Italic
    .replace(/__(.+?)__/g, '$1')             // Bold (underscore)
    .replace(/_(.+?)_/g, '$1')               // Italic (underscore)
    
    // Remove links but keep text
    .replace(/\[(.+?)\]\(.+?\)/g, '$1')      // [text](url) -> text
    
    // Remove code blocks
    .replace(/```[\s\S]*?```/g, 'code block')  // Multi-line code
    .replace(/`(.+?)`/g, '$1')                 // Inline code
    
    // Remove headers
    .replace(/^#{1,6}\s+/gm, '')             // # Header -> Header
    
    // Remove horizontal rules
    .replace(/^[-*_]{3,}$/gm, '')
    
    // Remove blockquotes
    .replace(/^>\s+/gm, '')
    
    // Remove list markers
    .replace(/^[\s]*[-*+]\s+/gm, '')         // Unordered lists
    .replace(/^[\s]*\d+\.\s+/gm, '')         // Ordered lists
    
    // Clean up
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Prepares text for text-to-speech by removing emojis, icons, and markdown
 * @param text - The raw text
 * @returns Clean text suitable for TTS
 */
export function prepareForSpeech(text: string): string {
  if (!text) return '';
  
  let cleaned = text;
  
  // First strip markdown
  cleaned = stripMarkdown(cleaned);
  
  // Then remove emojis and icons
  cleaned = stripEmojisAndIcons(cleaned);
  
  return cleaned;
}

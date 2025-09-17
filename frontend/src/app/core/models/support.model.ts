export interface SupportTicket {
  id: string;
  userId: string;
  userType: 'customer' | 'shop_owner' | 'delivery_partner' | 'admin';
  title: string;
  description: string;
  category: SupportCategory;
  priority: SupportPriority;
  status: SupportStatus;
  assignedAgent?: string;
  agentName?: string;
  createdAt: Date;
  updatedAt: Date;
  resolvedAt?: Date;
  closedAt?: Date;
  messages: TicketMessage[];
  attachments: string[];
  metadata?: any;
  rating?: number;
  feedback?: string;
}

export interface TicketMessage {
  id: string;
  ticketId: string;
  senderId: string;
  senderName: string;
  senderType: 'user' | 'agent' | 'system';
  message: string;
  timestamp: Date;
  attachments: string[];
  isRead: boolean;
  messageType: 'text' | 'image' | 'file' | 'system';
}

export interface FAQ {
  id: string;
  question: string;
  answer: string;
  category: string;
  categoryName: string;
  tags: string[];
  viewCount: number;
  isHelpful: boolean;
  helpfulCount: number;
  notHelpfulCount: number;
  createdAt: Date;
  updatedAt: Date;
  relatedFAQs: string[];
  videoUrl?: string;
  isPublished: boolean;
  order: number;
}

export interface FAQCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
  faqCount: number;
  order: number;
  isActive: boolean;
}

export interface ContactMethod {
  id: string;
  name: string;
  type: 'phone' | 'whatsapp' | 'email' | 'chat';
  value: string;
  description: string;
  icon: string;
  isAvailable: boolean;
  availableHours?: string;
  responseTime: number; // in minutes
  order: number;
}

export interface ChatMessage {
  id: string;
  sessionId: string;
  senderId: string;
  senderName: string;
  senderType: 'user' | 'agent' | 'bot';
  message: string;
  timestamp: Date;
  isRead: boolean;
  messageType: 'text' | 'image' | 'file' | 'typing';
  attachments?: string[];
}

export interface ChatSession {
  id: string;
  userId: string;
  userName: string;
  userType: string;
  agentId?: string;
  agentName?: string;
  status: 'waiting' | 'active' | 'ended' | 'transferred';
  createdAt: Date;
  endedAt?: Date;
  messages: ChatMessage[];
  rating?: number;
  feedback?: string;
}

export interface SupportAgent {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  isOnline: boolean;
  currentChats: number;
  maxChats: number;
  expertise: string[];
  rating: number;
  totalTickets: number;
  resolvedTickets: number;
  averageResponseTime: number;
  lastActive: Date;
}

export interface SupportFeedback {
  id: string;
  userId: string;
  userName: string;
  userType: string;
  type: FeedbackType;
  title: string;
  message: string;
  rating: number;
  category: string;
  allowContact: boolean;
  createdAt: Date;
  status: 'new' | 'reviewed' | 'resolved';
  agentResponse?: string;
  responseDate?: Date;
}

export interface SupportAnalytics {
  totalTickets: number;
  openTickets: number;
  resolvedTickets: number;
  averageResolutionTime: number;
  customerSatisfactionScore: number;
  ticketsByCategory: { [category: string]: number };
  ticketsByPriority: { [priority: string]: number };
  agentPerformance: AgentPerformance[];
  responseTimeMetrics: ResponseTimeMetrics;
  feedbackSummary: FeedbackSummary;
}

export interface AgentPerformance {
  agentId: string;
  agentName: string;
  ticketsHandled: number;
  averageResolutionTime: number;
  customerRating: number;
  responseTime: number;
}

export interface ResponseTimeMetrics {
  averageFirstResponse: number;
  averageResolutionTime: number;
  slaCompliance: number;
  responseTimeByHour: { [hour: string]: number };
}

export interface FeedbackSummary {
  totalFeedback: number;
  averageRating: number;
  ratingDistribution: { [rating: string]: number };
  feedbackByType: { [type: string]: number };
}

export enum SupportCategory {
  GENERAL = 'general',
  ORDER_ISSUE = 'order_issue',
  PAYMENT_ISSUE = 'payment_issue',
  DELIVERY_ISSUE = 'delivery_issue',
  ACCOUNT_ISSUE = 'account_issue',
  TECHNICAL_ISSUE = 'technical_issue',
  FEEDBACK = 'feedback',
  FEATURE_REQUEST = 'feature_request',
  REFUND_REQUEST = 'refund_request',
  PRODUCT_QUALITY = 'product_quality'
}

export enum SupportPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent',
  CRITICAL = 'critical'
}

export enum SupportStatus {
  OPEN = 'open',
  IN_PROGRESS = 'in_progress',
  WAITING_FOR_USER = 'waiting_for_user',
  WAITING_FOR_AGENT = 'waiting_for_agent',
  ESCALATED = 'escalated',
  RESOLVED = 'resolved',
  CLOSED = 'closed'
}

export enum FeedbackType {
  GENERAL = 'general',
  APP_USABILITY = 'app_usability',
  DELIVERY_EXPERIENCE = 'delivery_experience',
  PRODUCT_QUALITY = 'product_quality',
  CUSTOMER_SERVICE = 'customer_service',
  SUGGESTION = 'suggestion',
  COMPLAINT = 'complaint',
  COMPLIMENT = 'compliment'
}

export interface SupportTicketFilter {
  status?: SupportStatus[];
  category?: SupportCategory[];
  priority?: SupportPriority[];
  assignedAgent?: string[];
  dateRange?: {
    startDate: Date;
    endDate: Date;
  };
  searchQuery?: string;
  userType?: string[];
}

export interface CreateTicketRequest {
  title: string;
  description: string;
  category: SupportCategory;
  priority: SupportPriority;
  attachments?: string[];
  metadata?: any;
}

export interface UpdateTicketRequest {
  status?: SupportStatus;
  assignedAgent?: string;
  priority?: SupportPriority;
  category?: SupportCategory;
}

export interface CreateFeedbackRequest {
  type: FeedbackType;
  title: string;
  message: string;
  rating: number;
  category?: string;
  allowContact: boolean;
}

export const SUPPORT_CATEGORY_LABELS = {
  [SupportCategory.GENERAL]: 'General Inquiry',
  [SupportCategory.ORDER_ISSUE]: 'Order Issue',
  [SupportCategory.PAYMENT_ISSUE]: 'Payment Issue',
  [SupportCategory.DELIVERY_ISSUE]: 'Delivery Issue',
  [SupportCategory.ACCOUNT_ISSUE]: 'Account Issue',
  [SupportCategory.TECHNICAL_ISSUE]: 'Technical Issue',
  [SupportCategory.FEEDBACK]: 'Feedback',
  [SupportCategory.FEATURE_REQUEST]: 'Feature Request',
  [SupportCategory.REFUND_REQUEST]: 'Refund Request',
  [SupportCategory.PRODUCT_QUALITY]: 'Product Quality'
};

export const SUPPORT_PRIORITY_LABELS = {
  [SupportPriority.LOW]: 'Low',
  [SupportPriority.MEDIUM]: 'Medium',
  [SupportPriority.HIGH]: 'High',
  [SupportPriority.URGENT]: 'Urgent',
  [SupportPriority.CRITICAL]: 'Critical'
};

export const SUPPORT_STATUS_LABELS = {
  [SupportStatus.OPEN]: 'Open',
  [SupportStatus.IN_PROGRESS]: 'In Progress',
  [SupportStatus.WAITING_FOR_USER]: 'Waiting for User',
  [SupportStatus.WAITING_FOR_AGENT]: 'Waiting for Agent',
  [SupportStatus.ESCALATED]: 'Escalated',
  [SupportStatus.RESOLVED]: 'Resolved',
  [SupportStatus.CLOSED]: 'Closed'
};

export const FEEDBACK_TYPE_LABELS = {
  [FeedbackType.GENERAL]: 'General Feedback',
  [FeedbackType.APP_USABILITY]: 'App Usability',
  [FeedbackType.DELIVERY_EXPERIENCE]: 'Delivery Experience',
  [FeedbackType.PRODUCT_QUALITY]: 'Product Quality',
  [FeedbackType.CUSTOMER_SERVICE]: 'Customer Service',
  [FeedbackType.SUGGESTION]: 'Suggestion',
  [FeedbackType.COMPLAINT]: 'Complaint',
  [FeedbackType.COMPLIMENT]: 'Compliment'
};
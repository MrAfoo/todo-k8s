"use client";

import { useState, useEffect, useRef, useCallback } from 'react';

// Define types for the Web Speech API
interface SpeechRecognitionEvent extends Event {
  results: SpeechRecognitionResultList;
  resultIndex: number;
}

interface SpeechRecognitionErrorEvent extends Event {
  error: string;
  message: string;
}

interface SpeechRecognition extends EventTarget {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  start(): void;
  stop(): void;
  abort(): void;
  onresult: ((event: SpeechRecognitionEvent) => void) | null;
  onerror: ((event: SpeechRecognitionErrorEvent) => void) | null;
  onend: (() => void) | null;
  onstart: (() => void) | null;
}

interface SpeechRecognitionConstructor {
  new (): SpeechRecognition;
}

declare global {
  interface Window {
    SpeechRecognition: SpeechRecognitionConstructor;
    webkitSpeechRecognition: SpeechRecognitionConstructor;
  }
}

interface UseVoiceRecognitionOptions {
  lang?: string;
  continuous?: boolean;
  interimResults?: boolean;
  onResult?: (transcript: string, isFinal: boolean) => void;
  onError?: (error: string) => void;
}

export function useVoiceRecognition(options: UseVoiceRecognitionOptions = {}) {
  const {
    lang = 'en-US',
    continuous = false,
    interimResults = true,
    onResult,
    onError,
  } = options;

  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [interimTranscript, setInterimTranscript] = useState('');
  const [isSupported, setIsSupported] = useState(false);
  const recognitionRef = useRef<SpeechRecognition | null>(null);

  useEffect(() => {
    // Check if speech recognition is supported
    if (typeof window !== 'undefined') {
      const SpeechRecognitionAPI = window.SpeechRecognition || window.webkitSpeechRecognition;
      setIsSupported(!!SpeechRecognitionAPI);

      if (SpeechRecognitionAPI) {
        recognitionRef.current = new SpeechRecognitionAPI();
        recognitionRef.current.continuous = continuous;
        recognitionRef.current.interimResults = interimResults;
        recognitionRef.current.lang = lang;

        recognitionRef.current.onresult = (event: SpeechRecognitionEvent) => {
          let interimText = '';
          let finalText = '';

          for (let i = event.resultIndex; i < event.results.length; i++) {
            const result = event.results[i];
            const text = result[0].transcript;

            if (result.isFinal) {
              finalText += text + ' ';
            } else {
              interimText += text;
            }
          }

          if (finalText) {
            setTranscript((prev) => prev + finalText);
            setInterimTranscript('');
            onResult?.(finalText.trim(), true);
          } else if (interimText) {
            setInterimTranscript(interimText);
            onResult?.(interimText.trim(), false);
          }
        };

        recognitionRef.current.onerror = (event: SpeechRecognitionErrorEvent) => {
          console.error('Speech recognition error:', event.error);
          setIsListening(false);
          
          // Don't show error for aborted - it's usually intentional
          if (event.error === 'aborted') {
            return;
          }
          
          let errorMessage = 'An error occurred with speech recognition.';
          switch (event.error) {
            case 'no-speech':
              errorMessage = 'No speech detected. Please try again.';
              break;
            case 'audio-capture':
              errorMessage = 'Microphone not found or not accessible.';
              break;
            case 'not-allowed':
              errorMessage = 'Microphone access denied. Please enable microphone permissions.';
              break;
            case 'network':
              errorMessage = 'Network error occurred.';
              break;
          }
          
          onError?.(errorMessage);
        };

        recognitionRef.current.onend = () => {
          setIsListening(false);
        };

        recognitionRef.current.onstart = () => {
          setIsListening(true);
        };
      }
    }

    return () => {
      // Cleanup: stop recognition gracefully on unmount
      if (recognitionRef.current) {
        try {
          // Use stop() instead of abort() for cleaner shutdown
          recognitionRef.current.stop();
        } catch (error) {
          // Ignore cleanup errors
          console.debug('Cleanup: Speech recognition already stopped');
        }
      }
    };
  }, [lang, continuous, interimResults, onResult, onError]);

  const startListening = useCallback(() => {
    if (!recognitionRef.current) return;
    
    // If already listening, don't start again
    if (isListening) return;

    try {
      setTranscript('');
      setInterimTranscript('');
      recognitionRef.current.start();
    } catch (error: any) {
      // Ignore "already started" errors
      if (error.message && error.message.includes('already started')) {
        console.warn('Speech recognition already running');
        return;
      }
      console.error('Error starting speech recognition:', error);
      onError?.('Failed to start speech recognition.');
    }
  }, [isListening, onError]);

  const stopListening = useCallback(() => {
    if (!recognitionRef.current) return;
    
    // Only stop if actually listening
    if (!isListening) return;

    try {
      recognitionRef.current.stop();
    } catch (error: any) {
      // Ignore errors if recognition is not running
      console.warn('Error stopping speech recognition:', error);
    }
  }, [isListening]);

  const resetTranscript = useCallback(() => {
    setTranscript('');
    setInterimTranscript('');
  }, []);

  return {
    isListening,
    transcript,
    interimTranscript,
    isSupported,
    startListening,
    stopListening,
    resetTranscript,
  };
}

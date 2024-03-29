import { OutputFormat, LexFormat } from '../types/common.ts'

export const parseOutputFormat = (outputFormat: OutputFormat): string => {
  switch (outputFormat) {
    case OutputFormat.SRT:
      return 'srt'
    case OutputFormat.TXT:
      return 'text'
  }
}

export const parseLexFormat = (lexFormat: LexFormat): string => {
  switch (lexFormat) {
    case LexFormat.SAMPA:
      return 'lex'
    case LexFormat.KALDI:
      return 'klex'
    case LexFormat.UASR:
      return 'ulex'
  }
}

export const removeExtension = (input: string): string => input.split('.').slice(0, -1).join('')

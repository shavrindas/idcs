// src/services/omnibox.ts

/**
 * 스마트 검색 입력에서 날짜·시각을 떼어 낸다.
 *
 * 입력에는 이름과 시점이 섞여 들어온다 ('다온인터내셔널 냉동 1호 8/17 11:30').
 * 시점은 이름이 아니므로 먼저 걷어내야 남은 낱말로 시설·호실을 찾을 수 있다.
 * 예전에는 이 작업을 엔터를 누른 뒤에만 해서, 타이핑하는 동안에는 드롭다운에
 * 아무것도 뜨지 않았다.
 */
export interface DateTimeParse {
  date: Date;
  dateChanged: boolean;
  timeChanged: boolean;
  /** 날짜·시각을 떼고 남은 글자. 이름을 찾는 데 쓴다. */
  remaining: string;
}

const DATE_YMD = /(?:^|\s)(\d{4})[./-](\d{1,2})[./-](\d{1,2})(?:\s|$)/;
const DATE_MD = /(?:^|\s)(\d{1,2})[./-](\d{1,2})(?:\s|$)/;
const DATE_KO = /(?:^|\s)(\d{1,2})\s*월\s*(\d{1,2})\s*일(?:\s|$)/;
const TIME_COLON = /(?:^|\s)([01]\d|2[0-3]):([0-5]\d)(?:\s|$)/;
const TIME_PLAIN = /(?:^|\s)([01]\d|2[0-3])([0-5]\d)(?:\s|$)/;

export const extractDateTime = (input: string, base: Date = new Date()): DateTimeParse => {
  let remaining = input;
  const date = new Date(base.getTime());
  let dateChanged = false;
  let timeChanged = false;

  let m: RegExpMatchArray | null;
  if ((m = remaining.match(DATE_YMD))) {
    date.setFullYear(parseInt(m[1]), parseInt(m[2]) - 1, parseInt(m[3]));
    remaining = remaining.replace(m[0], ' ');
    dateChanged = true;
  } else if ((m = remaining.match(DATE_KO))) {
    date.setMonth(parseInt(m[1]) - 1, parseInt(m[2]));
    remaining = remaining.replace(m[0], ' ');
    dateChanged = true;
  } else if ((m = remaining.match(DATE_MD))) {
    date.setMonth(parseInt(m[1]) - 1, parseInt(m[2]));
    remaining = remaining.replace(m[0], ' ');
    dateChanged = true;
  }

  if ((m = remaining.match(TIME_COLON))) {
    date.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0);
    remaining = remaining.replace(m[0], ' ');
    timeChanged = true;
  } else if ((m = remaining.match(TIME_PLAIN))) {
    date.setHours(parseInt(m[1]), parseInt(m[2]), 0, 0);
    remaining = remaining.replace(m[0], ' ');
    timeChanged = true;
  }

  // 날짜만 적었으면 그날 00:00 부터 본다.
  if (dateChanged && !timeChanged) date.setHours(0, 0, 0, 0);

  return { date, dateChanged, timeChanged, remaining: remaining.trim() };
};

/**
 * 고른 이름을 입력에서 뺀다. 공백이 들어간 이름('냉동 1호')도 지워지도록
 * 띄어쓰기를 무시하고 찾는다.
 */
export const removeName = (input: string, name: string): string => {
  const flatName = name.replace(/\s+/g, '');
  if (!flatName) return input;

  // 띄어쓰기를 건너뛰며 글자를 맞춘다.
  const pattern = flatName.split('').map(ch => ch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('\\s*');
  return input.replace(new RegExp(pattern, 'i'), ' ').replace(/\s+/g, ' ').trim();
};

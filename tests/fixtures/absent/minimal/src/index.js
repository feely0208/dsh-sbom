import dayjs from 'dayjs';

export function stamp(at) {
  return dayjs(at).format('YYYY-MM-DD HH:mm:ss');
}

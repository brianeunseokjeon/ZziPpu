export enum DiaperType {
  Pee = "pee",
  Poop = "poop",
  Both = "both",
}

export enum StoolColor {
  Yellow = "yellow",
  Green = "green",
  Brown = "brown",
  Black = "black",
  Red = "red",
  White = "white",
}

export enum StoolState {
  Liquid = "liquid",
  Soft = "soft",
  Normal = "normal",
  Hard = "hard",
}

export interface DiaperRecord {
  id: string;
  babyId: string;
  type: DiaperType;
  stoolColor?: StoolColor;
  stoolState?: StoolState;
  occurredAt: string;
  memo?: string;
  createdAt: string;
}

export interface CreateDiaperRequest {
  babyId: string;
  type: DiaperType;
  stoolColor?: StoolColor;
  stoolState?: StoolState;
  occurredAt: string;
  memo?: string;
}

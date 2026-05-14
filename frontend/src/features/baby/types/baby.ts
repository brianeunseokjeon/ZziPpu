export interface Baby {
  id: string;
  userId: string;
  name: string;
  birthDate: string;
  gender: "male" | "female";
  birthWeightG: number;
  createdAt: string;
}

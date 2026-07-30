export type Dictionary<Value = unknown> = Record<string, Value>;
export type MaybePromise<Value> = Promise<Value> | Value;
export type Nullable<Value> = Value | null;
export type Optional<Value> = Value | undefined;
export type StringKeyOf<Value> = Extract<keyof Value, string>;

export type DeepReadonly<Value> = Value extends (...arguments_: never[]) => unknown
  ? Value
  : Value extends readonly (infer Item)[]
    ? readonly DeepReadonly<Item>[]
    : Value extends object
      ? { readonly [Key in keyof Value]: DeepReadonly<Value[Key]> }
      : Value;

declare module 'd3-shape' {
  export interface CurveFactory {
    (context: any): any;
  }
  
  export const curveCardinal: CurveFactory;
  export const curveLinear: CurveFactory;
  export const curveMonotoneX: CurveFactory;
  export const curveStep: CurveFactory;
}

declare module 'd3-scale' {
  export interface ScaleLinear<Range, Output> {
    (value: number): Output;
    domain(): number[];
    domain(domain: number[]): this;
    range(): Range[];
    range(range: Range[]): this;
  }
  
  export function scaleLinear(): ScaleLinear<number, number>;
}

declare module 'd3-selection' {
  export interface Selection<GElement extends Element, Datum, PElement extends Element, PDatum> {
    select(selector: string): Selection<any, Datum, PElement, PDatum>;
    selectAll(selector: string): Selection<any, any, GElement, Datum>;
    attr(name: string, value: any): this;
    style(name: string, value: any): this;
  }
  
  export function select(selector: string): Selection<any, any, any, any>;
}
/**
 * Created by Youri GICQUEL
 */
package {
import aerys.minko.render.geometry.Geometry;
import aerys.minko.render.geometry.GeometrySanitizer;
import aerys.minko.render.geometry.stream.IVertexStream;
import aerys.minko.render.geometry.stream.IndexStream;
import aerys.minko.render.geometry.stream.StreamUsage;
import aerys.minko.render.geometry.stream.VertexStream;
import aerys.minko.render.geometry.stream.format.VertexComponent;
import aerys.minko.render.geometry.stream.format.VertexFormat;
import aerys.minko.render.material.Material;
import aerys.minko.render.material.basic.BasicMaterial;
import aerys.minko.render.material.phong.PhongEffect;
import aerys.minko.scene.node.Group;
import aerys.minko.scene.node.Mesh;
import aerys.minko.type.enum.TriangleCulling;


import flash.geom.Vector3D;

import flash.utils.ByteArray;

public final class PLYASCII {

    private var vertex:Vector.<Number> = new <Number>[];
    private var _verts:int;
    private var _faces:int;
    private var final_index:Vector.<uint> = new <uint>[];
    private var indexT:Vector.<uint> = new <uint>[];
    private var indexQ:Vector.<uint> = new <uint>[];
    private var vertexQ:Vector.<Number> = new <Number>[];
    private var vertexT:Vector.<Number> = new <Number>[];
    public var color:Vector.<Number> = new <Number>[];

    private var indexTri:ByteArray = new ByteArray();
    private var indexQuad:ByteArray = new ByteArray();
    private var vertexTri:ByteArray = new ByteArray();
    private var vertexQuad:ByteArray = new ByteArray();

    private var _p1:Vector3D = new Vector3D();
    private var _p2:Vector3D = new Vector3D();
    private var _p3:Vector3D = new Vector3D();

    private var _norm:Vector3D = new Vector3D();

    private var _r:Number;
    private var _g:Number;
    private var _b:Number;

    private var normals:Boolean;
    private var colors:Boolean;


    private function generateNormal():void {
        var i:int = 0;
        var pos:int = 0;
        var tmp:Vector.<Number> = new <Number>[];

        while (i < final_index.length){
            pos = final_index[i] * 3;
            _p1.x = vertex[pos];
            _p1.y = vertex[pos + 1];
            _p1.z = vertex[pos + 2];
            i++;
            pos = final_index[i] * 3;
            _p2.x = vertex[pos];
            _p2.y = vertex[pos + 1];
            _p2.z = vertex[pos + 2];
            i++;
            pos = final_index[i] * 3;
            _p3.x = vertex[pos];
            _p3.y = vertex[pos + 1];
            _p3.z = vertex[pos + 2];
            i++;
            _norm.x = (_p2.x - _p1.x) * (_p3.z - _p1.z) - (_p2.z - _p1.z) * (_p3.y - _p1.y);
            _norm.y = (_p2.z - _p1.z) * (_p3.x - _p1.x) - (_p2.x - _p1.x) * (_p3.z - _p1.z);
            _norm.z = (_p2.x - _p1.x) * (_p3.y - _p1.y) - (_p2.y - _p1.y) * (_p3.x - _p1.x);
            tmp.push(_p1.x, _p1.y, _p1.z);
            tmp.push(_norm.x, _norm.y, _norm.z);
            tmp.push(_p2.x, _p2.y, _p2.z);
            tmp.push(_norm.x, _norm.y, _norm.z);
            tmp.push(_p3.x, _p3.y, _p3.z);
            tmp.push(_norm.x, _norm.y, _norm.z);
        }
        vertexT = tmp;
    }

    private function newVertices(pos:int, tab:ByteArray):void {
        var tmp:String;
        var i:int = pos;

        while (String(tab).charAt(i) != '\n')
            i++;
        pos += 15;
        tmp = String(tab).slice(pos, i);
        _verts = parseInt(tmp);
    }

    private function newFaces(pos:int, tab:ByteArray):void {
        var tmp:String;
        var i:int;

        i = pos;
        while (String(tab).charAt(i) != '\n')
            i++;
        pos += 13;
        tmp = String(tab).slice(pos, i);
        _faces = parseInt(tmp);
    }

    private function checkContent(tab:ByteArray):void {
        if (String(tab).indexOf("property float nx") > 0)
            normals = true;
        if (String(tab).indexOf("property uchar red") > 0)
            colors = true;
    }

    private static function newTab(tmp:String):String {
        var i:int;

        i = 0;
        while ((tmp.charAt(i) >= '0' && tmp.charAt(i) <= '9') ||
                tmp.charAt(i) == '.' || tmp.charAt(i) == '-')
            i++;
        tmp = tmp.slice(++i, tmp.length);
        return (tmp);
    }

    private function addVertices(tab:String, pos:int):String {
        var tmp:String;
        var i:int;

        i = pos;
        while (tab.charAt(i) != '\n')
            i++;
        tmp = tab.slice(pos, i);
        _p1.x = parseFloat(tmp);
        tmp = newTab(tmp);
        _p1.y = parseFloat(tmp);
        tmp = newTab(tmp);
        _p1.z = parseFloat(tmp);
        tmp = newTab(tmp);
        return (tmp);
    }

    private function addFace(tab:String, pos:int):String {
        var tmp:String;
        var i:int = pos;
        var cpt:int = 0;
        var nb:int;
        var test:uint;

        while (tab.charAt(i) != '\n')
            i++;
        tmp = tab.slice(pos, i);
        nb = parseInt(tmp);
        if (nb == 3) {
            while (cpt < 3){
                tmp = newTab(tmp);
                indexTri.writeInt(parseInt(tmp));
                cpt++;
            }
        }
        else if (nb == 4) {
            tmp = newTab(tmp);
            test = parseInt(tmp);
            indexQuad.writeInt(test);
            tmp = newTab(tmp);
            while (cpt < 3){
                indexQuad.writeInt(parseInt(tmp));
                tmp = newTab(tmp);
                cpt++;
            }
        }
        return (tmp);
    }

    private function addNormal(tmp:String):String {
        _norm.x = parseFloat(tmp);
        tmp = newTab(tmp);
        _norm.y = parseFloat(tmp);
        tmp = newTab(tmp);
        _norm.z = parseFloat(tmp);
        tmp = newTab(tmp);
        return (tmp);
    }

    private function addColor(tmp:String, tab:String, pos:int):String {
        var i:int = pos;

        while (tab.charAt(i) != '\n')
            i++;
        _r = parseFloat(tmp);
        tmp = newTab(tmp);
        _g = parseFloat(tmp);
        tmp = newTab(tmp);
        _b = parseFloat(tmp);
        tmp = newTab(tmp);
        return (tmp);
    }

    private function exist():void {
        vertex.push(_p1.x, _p1.y, _p1.z);
        if (colors){
            vertex.push(_r, _g, _b);
        }
        vertex.push(_norm.x, _norm.y, _norm.z);
    }

    private function dupliVert():void {
        var i:int;

        i = 0;
        while (i < vertex.length) {
            vertexQuad.writeFloat(vertex[i]);
            vertexTri.writeFloat(vertex[i]);
            i++;
        }
        vertexQuad.position = 0;
        vertexTri.position = 0;
    }

    private function toNum():void {
        vertexQuad.position = 0;
        vertexTri.position = 0;
        indexTri.position = 0;
        indexQuad.position = 0;

        while (indexQuad.bytesAvailable > 0) {
            indexQ.push(indexQuad.readInt());
        }
        while (indexTri.bytesAvailable > 0) {
            indexT.push(indexTri.readInt());
        }
        while (vertexQuad.bytesAvailable > 0) {
            vertexQ.push(vertexQuad.readFloat());
        }
        while (vertexTri.bytesAvailable > 0) {
            vertexT.push(vertexTri.readFloat());
        }
    }

    private function creaFace(tmp:Vector.<uint>):void {
        final_index.push(tmp[0]);
        final_index.push(tmp[1]);
        final_index.push(tmp[2]);
        final_index.push(tmp[3]);
        final_index.push(tmp[0]);
        final_index.push(tmp[2]);
    }

    private function splitQuad():void {
        var i:int = 0;
        var pos:int = i;
        var tmp:Vector.<uint> = new <uint>[];

        while (i < indexQ.length) {
            if ((i % 4) == 0 && i > 0) {
                tmp = indexQ.slice(pos, i);
                creaFace(tmp);
                pos = i;
            }
            i++;
        }
        tmp = indexQ.slice(pos, i);
        if (indexQ.length > 0)
            creaFace(tmp);
    }

    private function addTriangles():void {
        var i:int = 0;

        while (i < indexT.length) {
            final_index.push(indexT[i]);
            i++;
        }
    }

    private function extract(tab:String):void {
        var pos:int = tab.indexOf("end_header");
        var line:int = 0;
        var tmp:String;

        while (line < _verts) {
            while (tab.charAt(pos) != '\n' && pos < tab.length)
                pos++;
            pos++;
            tmp = addVertices(tab, pos);
            if (normals == true)
                tmp = addNormal(tmp);
            if (colors == true)
                tmp = addColor(tmp, tab, pos);
            exist();
            line++;
        }
        line = 0;
        while (line < _faces) {
            while (tab.charAt(pos) != '\n' && pos < tab.length)
                pos++;
            pos++;
            addFace(tab, pos);
            line++;
        }
        indexQuad.position = 0;
        dupliVert();
    }

    public function parsing(tab:ByteArray):Group {
        vertexQuad.position = 0;
        vertexTri.position = 0;
        indexTri.position = 0;
        indexQuad.position = 0;

        checkContent(tab);
        newVertices(String(tab).indexOf("element vertex "), tab);
        newFaces(String(tab).indexOf("element face "), tab);
        extract(String(tab));
        toNum();
        if (vertexQ.length > 0)
            splitQuad();
        addTriangles();
        GeometrySanitizer.removeDuplicatedVertices(vertexTri, indexTri, 12);
        GeometrySanitizer.removeDuplicatedVertices(vertexQuad, indexQuad, 12);
        generateNormal();
        return (generateMesh());
    }

    private function generateMesh():Group {
        var group:Group = new Group();

        var mesh:Mesh;
        var geom:Geometry;
        var material:Material;

        // générer l'indexStream
        var indexStream:IndexStream = IndexStream.fromVector(StreamUsage.DYNAMIC, final_index);

        var verticesStream:Vector.<IVertexStream> = new <IVertexStream>[];

        // générer le vertex buffer
        var format:VertexFormat = new VertexFormat();
        format.addComponent(VertexComponent.XYZ);
        //if (normal == true)
        format.addComponent(VertexComponent.NORMAL);
        if (color == true)
            format.addComponent(VertexComponent.RGB);

        // ajout des composants format
        var vertexStream:VertexStream = VertexStream.fromVector(StreamUsage.DYNAMIC, format, vertex);
        verticesStream.push(vertexStream);

        geom = new Geometry(verticesStream, indexStream);
        material = new BasicMaterial(
                {diffuseColor: 0xEEEEEEFF,
                    triangleCulling: TriangleCulling.NONE},
                new PhongEffect()
        );
        mesh = new Mesh(geom, material);

        group.addChild(mesh);
        return group;
    }

    public function PLYASCII() {
    }
}
}
